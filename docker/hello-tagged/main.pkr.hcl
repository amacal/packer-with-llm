packer {
  required_plugins {
    docker = {
      version = "1.1.4"
      source  = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "ubuntu2404" {
  image  = "ubuntu:24.04"
  commit = true
}

build {
  name = "hello-tagged"
  sources = [
    "source.docker.ubuntu2404"
  ]

  provisioner "shell" {
    inline = [
      "echo Hello, World! | tee /tmp/hello.txt",
      "apt-get update && apt-get install -y tree"
    ]
  }

  post-processor "docker-tag" {
    repository = "hello-tagged"
    tags       = ["latest"]
  }
}
