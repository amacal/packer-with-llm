SSH_PUBLIC_KEY=$(shell ssh-add -L | head -n 1 | cut -d' ' -f1,2)

.PHONY: init
init:
	@packer init main.pkr.hcl

.PHONY: fmt
fmt:
	@packer fmt -check main.pkr.hcl

.PHONY: clean
clean:
	@rm -rf output-hello

.PHONY: validate
validate:
	@packer validate --var "ssh_public_key=$(SSH_PUBLIC_KEY)" main.pkr.hcl

.PHONY: build
build:
	@packer build --var "ssh_public_key=$(SSH_PUBLIC_KEY)" main.pkr.hcl

.PHONY: login-packer
login-packer:
	@ssh -p 2222 -o PubkeyAuthentication=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null packer@127.0.0.1

.PHONY: login-guest
login-guest:
	@ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null guest@127.0.0.1
