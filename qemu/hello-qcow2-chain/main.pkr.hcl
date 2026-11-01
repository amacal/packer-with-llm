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

  iso_url      = "https://cloud.debian.org/images/cloud/trixie/20261026-2643/debian-13-genericcloud-amd64-20261026-2643.qcow2"
  iso_checksum = "sha512:3ace18e33bdd036edb49d1f79342bd01d2ab980e35194edb0b410435cd543538d286a0bd13bbb0835f7862306e3d385ce2f6a70d8ecf0bd961111166adbc1b8e"

  shutdown_command = "sudo shutdown -P now"
  output_directory = "output-qcow2-chain"
}

build {
  name = "hello-qcow2-chain"
  sources = [
    "source.qemu.debian13"
  ]

  provisioner "shell" {
    inline = [
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

  post-processors {
    post-processor "compress" {
      output              = ".tmp/trixie13.tar.gz"
      keep_input_artifact = false
    }

    post-processor "checksum" {
      checksum_types = ["sha512"]
      output         = ".tmp/trixie13.tar.gz.sha512"
    }
  }
}
