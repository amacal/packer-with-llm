packer {
  required_plugins {
    qemu = {
      version = "1.1.7"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "guest_username" {
  type = string

  validation {
    condition     = can(regex("^[a-z]{2,}$", var.guest_username))
    error_message = "Variable guest_username must be at least 2 lowercase letters."
  }
}

variable "guest_public_key" {
  type      = string
  sensitive = true

  validation {
    condition     = can(regex("^ssh-", var.guest_public_key))
    error_message = "Variable guest_public_key must start with 'ssh-'."
  }
}

variable "provisioner_username" {
  type = string

  validation {
    condition     = can(regex("^[a-z]{2,}$", var.provisioner_username))
    error_message = "Variable provisioner_username must be at least 2 lowercase letters."
  }
}

variable "provisioner_password" {
  type      = string
  sensitive = true

  validation {
    condition     = can(regex("^[^\\s]{6,}$", var.provisioner_password))
    error_message = "Variable provisioner_password must be at least 6 characters and cannot contain whitespace."
  }
}

variable "instance_id" {
  type    = string
  default = "iid-7341834751"

  validation {
    condition     = can(regex("^iid-[0-9]{10}$", var.instance_id))
    error_message = "Variable instance_id must match the pattern 'iid-XXXXXXXXXX' where X is a digit."
  }
}

source "qemu" "debian12" {
  disk_image = true
  headless   = true

  ssh_username = var.provisioner_username
  ssh_password = var.provisioner_password

  cd_label = "CIDATA"
  cd_content = {
    "meta-data" = templatefile("meta-data", {
      instance_id = var.instance_id
    })
    "user-data" = templatefile("user-data", {
      provisioner_username = var.provisioner_username
      provisioner_password = var.provisioner_password
    })
  }

  iso_url      = "https://cloud.debian.org/images/cloud/bookworm/20260923-2610/debian-12-genericcloud-amd64-20260923-2610.qcow2"
  iso_checksum = "sha512:3d94c9dd66d8a283fde060b8810373b7ae04038b956ee00d553d1ae564f6fbdeaa2fd6e7404e87e53348b5a9509170f3ea7c0731ba737590c5c4cb8d559a47f8"

  shutdown_command = <<EOF
    sudo sh -c '
      userdel -rf ${var.provisioner_username} &&
      rm -rf /home/${var.provisioner_username} &&
      rm -f /etc/sudoers.d/90-cloud-init-users &&
      shutdown -P now
    '
  EOF
}

build {
  name = "debian12"
  sources = [
    "source.qemu.debian12"
  ]

  provisioner "shell" {
    inline = [
      "echo Hello, World! | tee /tmp/hello.txt",
      "apt-get update && apt-get install -y tree"
    ]

    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
  }

  provisioner "shell" {
    inline = [
      "useradd -mUs /bin/bash ${var.guest_username}",
      "install -dm 700 -o ${var.guest_username} -g ${var.guest_username} /home/${var.guest_username}/.ssh",
      "install -m 600 -o ${var.guest_username} -g ${var.guest_username} /dev/null /home/${var.guest_username}/.ssh/authorized_keys",
      "echo $GUEST_PUBLIC_KEY >> /home/${var.guest_username}/.ssh/authorized_keys",
      "cat /home/${var.guest_username}/.ssh/authorized_keys | wc -l"
    ]

    environment_vars = [
      "GUEST_PUBLIC_KEY=${var.guest_public_key}"
    ]

    use_env_var_file = true
    execute_command  = "chmod +x {{.Path}}; sudo sh -c '. {{.EnvVarFile}} && {{ .Path }}'"
  }

  provisioner "file" {
    source      = "01-ssh-dropin.conf"
    destination = "/tmp/01-ssh-dropin.conf"
  }

  provisioner "shell" {
    inline = [
      "install -o root -g root -m 644 /tmp/01-ssh-dropin.conf /etc/ssh/sshd_config.d/01-ssh-dropin.conf",
      "rm -f /tmp/01-ssh-dropin.conf"
    ]

    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
  }

  provisioner "shell" {
    inline = [
      "passwd -l ${var.provisioner_username}",
      "rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf",
      "rm -rf /var/lib/cloud/instances/${var.instance_id}"
    ]

    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
  }
}
