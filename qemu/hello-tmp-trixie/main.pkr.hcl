packer {
  required_plugins {
    qemu = {
      version = "1.1.7"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "debian13" {
  disk_image = true
  headless   = true

  ssh_username = "packer"
  ssh_password = "packer"

  cd_label = "CIDATA"
  cd_files = ["user-data", "meta-data"]

  iso_url      = "https://cloud.debian.org/images/cloud/trixie/20261001-2618/debian-13-genericcloud-amd64-20261001-2618.qcow2"
  iso_checksum = "sha512:f46f0671a6e5bdec5291ab8972bae2f10e5408c2f64a74078f11efc2f06a436a9d0313ed50e0472542eeabf780e9f7c792ac0a314c6c20507fcd9fd81b468c3d"

  shutdown_command = "sudo shutdown -P now"
  output_directory = "output-hello-tmp-trixie"
}

build {
  name = "hello-tmp-trixie"
  sources = [
    "source.qemu.debian13"
  ]

  provisioner "shell" {
    inline = [
      "findmnt /tmp",
      "echo Hello, World! | tee /tmp/hello.txt",
      "apt-get update && apt-get install -y tree"
    ]

    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
  }

  provisioner "shell" {
    inline = [
      "passwd -l packer",
      "rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf"
    ]

    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
  }
}
