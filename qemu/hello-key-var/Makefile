SSH_PUBLIC_KEY=$(shell ssh-add -L | head -n 1 | cut -d' ' -f1,2)

.PHONY: fmt
fmt:
	@packer fmt -check main.pkr.hcl

.PHONY: validate
validate:
	@rm -rf output-hello
	@packer validate --var "ssh_public_key=$(SSH_PUBLIC_KEY)" main.pkr.hcl

.PHONY: build
build:
	@rm -rf output-hello
	@packer build --var "ssh_public_key=$(SSH_PUBLIC_KEY)" main.pkr.hcl
