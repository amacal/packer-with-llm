.PHONY: init
init:
	@packer init main.pkr.hcl

.PHONY: fmt
fmt:
	@packer fmt -check main.pkr.hcl

.PHONY: validate
validate:
	@packer validate main.pkr.hcl

.PHONY: build
build:
	@packer build main.pkr.hcl
