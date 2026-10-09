# Sensitive Build Credential via an Environment Variable (qemu, debian)

## Overview

Every earlier qemu exercise wrote the throwaway build password literally into two tracked files, the template's `ssh_password` and the seed's `plain_text_passwd`. That was tolerable only because the template locked the account afterwards, as `qemu/hello-image.md` explains. This exercise, built on the same Debian 12 genericcloud base, makes the password exist only at invocation time and then asks where it actually travels. The value is declared as a `sensitive` input variable and supplied only through a `PKR_VAR_provisioner_password` environment variable. The seed's `user-data` is rendered from that variable by the HCL2 function `templatefile` and placed on the CIDATA CD through the qemu builder's `cd_content`. The template then removes every copy the build left inside the guest. Several mechanisms appear here for the first time: `sensitive`, HCL2 functions, `cd_content` and heredoc strings. This file therefore explains each one only as far as the exercise needs it.

## What each protection actually covers

Supplying a value through `-var` or through `PKR_VAR_` affects two different exposures, and they are easy to conflate. Shell history depends only on how the value entered the shell: `export PKR_VAR_x=<value>` typed literally lands in history exactly like `-var x=<value>`, while `read -s` keeps either form out of it. The process table is where the channels genuinely differ. A `-var` value sits in the process's argument vector, which `ps` shows to every user on the host. An environment value sits in `/proc/<pid>/environ`, readable only by the process owner and root, and inherited by every child process. The precedence order among these sources is already derived in `qemu/hello-key-var.md` and is reused here unchanged.

The documentation says that `sensitive = true` obfuscates a variable's string values "from Packer's output". That is a statement about what Packer prints and nothing more. The guest must still receive the real value, or cloud-init would set the password to the literal text `<sensitive>` and the communicator's login would fail. So `sensitive` can never promise anything about the seed, the host's temporary files, or the finished disk.

## Observable behavior

The first build printed nothing containing the value, and the string `<sensitive>` also appeared zero times, because nothing ever tried to print the value. A temporary provisioner that echoed the variable then produced `Provisioner password: <sensitive>` in both the normal output and the `PACKER_LOG=1` debug log, with zero occurrences of the real value. That run is the actual evidence that masking happened.

Booting the first iteration's artifact, which still used only `passwd -l`, with a new-instance seed showed two survivors. `/etc/shadow` held `packer:!$y$j9T$<salt>$<hash>`, and `sudo grep -rl` found the plain value in four files under `/var/lib/cloud/instances/iid-01234567/`: `user-data.txt` (root, mode 600), `user-data.txt.i`, `cloud-config.txt` and `obj.pkl`.

The final template was built twice with distinct passwords, and both artifacts were booted with the `iid-verify-01` seed. On each, `id packer` answered `no such user`, and `/etc/shadow` and `/etc/passwd` held no `packer` line. `/home` contained only `guest` and `verify`, `/var/lib/cloud/instances/` held only `iid-verify-01`, and `sshd -T` printed `passwordauthentication no`. `90-cloud-init-users` held only the `verify` rule. A search for the key `plain_text_passwd` found no rendered seed outside cloud-init's own code and the verification grep's own sudo log line in the journal.

## Internal mechanism

The value enters the shell's environment through `read -s` and `export`. `make` inherits it and re-exports it as `PKR_VAR_provisioner_password` for the `build` target, and Packer binds it to `var.provisioner_password`. From there it goes two ways. `ssh_password` hands it to the SSH communicator. `templatefile("user-data", {...})` substitutes it for `${provisioner_password}` and returns a string, and `cd_content` maps that string to the CD filename `user-data`.

The debug log shows what the qemu plugin does with that map. It writes each entry as a plain file into a staging directory `/tmp/packer_to_cdrom<n>/`, and packs that directory with `xorriso -as genisoimage -volid CIDATA` into `/tmp/packer<n>.iso`. qemu attaches the ISO with `media=cdrom`, and after shutdown the plugin logs `Deleting CD disk`. Inside the guest, cloud-init's NoCloud datasource reads the CD. It hashes the value into `/etc/shadow`, writes the `packer` sudo rule into `/etc/sudoers.d/90-cloud-init-users`, and caches its input under `/var/lib/cloud/instances/<instance-id>/`.

`packer validate` evaluates `templatefile` too: given a placeholder with no matching key in the map, it fails with `vars map does not contain key`. But it cannot tell whether the resulting string is what cloud-init needs. When `file()` and `templatefile()` were accidentally swapped between `meta-data` and `user-data`, validation still passed.

## Design rationale

The three protections cover different risks, and none of them substitutes for another. `PKR_VAR_` keeps the value out of the host's process table. `sensitive` keeps it out of Packer's own output and debug log. Only explicit cleanup touches the artifact, because every cleanup step acts on one consumer's output and nothing else. `passwd -l` only prefixes the existing hash with `!`. The salted yescrypt hash stays intact, so anyone holding the qcow2 could still guess against it offline. Deleting `50-cloud-init.conf` touches only the sshd setting.

That is why the account is removed rather than locked, which settles the question left open in `qemu/hello-sshd-dropin.md`. Removing the account needed a placement argument. The communicator session itself runs as `packer`, so `userdel` from a provisioner refuses with `currently used by process`. `shutdown_command` is the last command Packer sends through that session, so the template puts `userdel -rf` there. `-f` overrides the in-use check, which is safe only because nothing runs as `packer` afterwards. Everything sits inside one `sudo sh -c`, so the account's disappearance cannot break the commands after it, and their order no longer matters.

The cloud-init cache is removed in the last provisioner by its instance-id. That costs nothing for an image meant to be launched as new instances, because each new instance gets its own first boot regardless. The heredoc form of `shutdown_command` exists because HCL rejects a quoted string that spans lines. The Makefile's default password, `$(shell openssl rand -hex 16)` assigned with `?=`, means nobody ever has to know the value. An exported value still overrides it, which is how the verification builds used values that could be searched for.

## Edge cases

During the build the rendered seed exists in plain text on the host, both as the staging file and inside the ISO, readable by whoever can read those paths. Both were absent from `/tmp` after the builds, but their permissions during the build were not checked. The sudoers rule is not derived from the password, yet it is a latent grant: any future account named `packer` would receive passwordless root. It is removed in `shutdown_command` alongside the account.

The exact-value disk search was run on the previous iteration's two builds and found nothing. For the final two builds only approximate recalled values were searched, also with no hits, together with the key-based checks. The only template change between the two iterations is one extra removal in `shutdown_command`.

## Worked example

Take the final template with an exported password P and the default instance id `iid-7341834751`. `templatefile` renders `user-data` with P in `plain_text_passwd`, and `cd_content` places it on a CIDATA ISO staged under the host's `/tmp`. The VM boots, cloud-init creates `packer` with P's hash in `/etc/shadow` and a sudo rule, and it caches the rendered file under `/var/lib/cloud/instances/iid-7341834751/`. The communicator logs in with P, which the log never shows.

The provisioners install `tree`, create `guest`, and install the sshd drop-in. The last provisioner runs `passwd -l`, deletes `50-cloud-init.conf`, and removes the cache directory, so at that point only the shadow hash and the sudo rule remain. Packer then sends the heredoc `shutdown_command`. Root's `userdel -rf packer` prints the in-use and missing-mail-spool warnings but still removes the shadow line and the home directory. The sudoers file is deleted next, and the VM powers off about two seconds later.

The plugin deletes the ISO and converts the disk. A new-instance boot of that disk finds no `packer` account, no build-instance cache and no `packer` sudo rule, and P appears nowhere that was searched.
