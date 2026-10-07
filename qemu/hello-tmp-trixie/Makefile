.PHONY: init
init:
	@packer init main.pkr.hcl

.PHONY: fmt
fmt:
	@packer fmt -check main.pkr.hcl

.PHONY: clean
clean:
	@rm -rf output-hello-tmp-trixie

.PHONY: validate
validate:
	@packer validate main.pkr.hcl

.PHONY: build
build:
	@packer build main.pkr.hcl

.PHONY: login
login:
	@ssh -p 2222 -o PubkeyAuthentication=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null packer@127.0.0.1
