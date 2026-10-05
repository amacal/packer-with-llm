packer {
  required_plugins {
    docker = {
      version = "1.1.4"
      source  = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "ubuntu" {
  image  = "ubuntu:24.04"
  commit = true
}

source "docker" "rocky" {
  image  = "rockylinux:9"
  commit = true
}

build {
  name = "hello-image"
  sources = [
    "source.docker.ubuntu",
    "source.docker.rocky"
  ]

  provisioner "shell" {
    inline = [
      "echo Hello, World! | tee /tmp/hello.txt",
    ]
  }

  provisioner "shell" {
    only = ["docker.ubuntu"]
    inline = [
      "apt-get update && apt-get install -y tree"
    ]
  }

  provisioner "shell" {
    only = ["docker.rocky"]
    inline = [
      "dnf install -y tree"
    ]
  }
}
