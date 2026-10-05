packer {
  required_plugins {
    docker = {
      version = "1.1.4"
      source  = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "hello" {
  image  = "ubuntu:24.04"
  commit = true
}

build {
  name = "hello-image"
  sources = [
    "source.docker.hello"
  ]

  provisioner "shell" {
    inline = [
      "echo Hello, World! | tee /tmp/hello.txt",
      "apt-get update && apt-get install -y tree"
    ]
  }
}
