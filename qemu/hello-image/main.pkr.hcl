packer {
  required_plugins {
    qemu = {
      version = "1.1.7"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "hello" {
  disk_image = true
  headless   = true

  ssh_username = "packer"
  ssh_password = "packer"

  cd_label = "CIDATA"
  cd_files = ["user-data", "meta-data"]

  iso_url      = "https://cloud.debian.org/images/cloud/bookworm/20260923-2610/debian-12-genericcloud-amd64-20260923-2610.qcow2"
  iso_checksum = "sha512:3d94c9dd66d8a283fde060b8810373b7ae04038b956ee00d553d1ae564f6fbdeaa2fd6e7404e87e53348b5a9509170f3ea7c0731ba737590c5c4cb8d559a47f8"

  shutdown_command = "sudo shutdown -P now"
}

build {
  name = "hello-image"
  sources = [
    "source.qemu.hello"
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
      "useradd -mUs /bin/bash guest",
      "install -dm 700 -o guest -g guest /home/guest/.ssh",
      "install -m 600 -o guest -g guest /dev/null /home/guest/.ssh/authorized_keys",
      "printf '%s\n' 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDirLJlZZeYpo8U6h8NSZQaj8KeDFHe8gYbY6gXY6h2BHXdRvjz5R+RLoTr9tDWb8z1sCsYZGonE9CWMzyx3HUX1926yMj++TdmZTwQAZ8b2wSIwCYwvPwVJS/2Kf0TuqKe6gfg3UTKy1CmxSg23bRLchNv+3n9pveAyt+NiVAIIxgrOQBH9LjmkV8sT+HjHS+9WtAC3PhMcpv/vQuQHXiCFPPAh8DR20J53a0lPD5oNx6T45458fBe7HdrilIraMV6xF0OaCuuvWOeviMeaw22abPFU6fL8Wv/Y7jb04Gk11LsQA4k2lbfdozHgFoTa2m5Tx0GGoYOhLcJDV2JrK5p' >> /home/guest/.ssh/authorized_keys"
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
