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
  name = "hello-tagged-chain"
  sources = [
    "source.docker.ubuntu2404"
  ]

  provisioner "shell" {
    inline = [
      "echo Hello, World! | tee /tmp/hello.txt",
      "apt-get update && apt-get install -y tree"
    ]
  }

  post-processors {
    post-processor "docker-tag" {
      repository = "hello-tagged-chain"
      tags       = ["latest"]
    }

    post-processor "docker-save" {
      path = ".tmp/hello-tagged-chain.tar"
    }

    post-processor "artifice" {
      files = [".tmp/hello-tagged-chain.tar"]
    }

    post-processor "checksum" {
      checksum_types = ["sha256"]
      output         = ".tmp/hello-tagged-chain.tar.sha256"
    }
  }
}
