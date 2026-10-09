GUEST_USERNAME   ?= guest
GUEST_PUBLIC_KEY ?= $(shell ssh-add -L | head -n 1 | cut -d' ' -f1,2)

PROVISIONER_USERNAME ?= packer
PROVISIONER_PASSWORD ?= $(shell openssl rand -hex 16)

# export needed variables
validate build: export PKR_VAR_guest_username = $(GUEST_USERNAME)
validate build: export PKR_VAR_guest_public_key = $(GUEST_PUBLIC_KEY)
validate build: export PKR_VAR_provisioner_username = $(PROVISIONER_USERNAME)
validate build: export PKR_VAR_provisioner_password = $(PROVISIONER_PASSWORD)

.PHONY: init
init:
	@packer init main.pkr.hcl

.PHONY: fmt
fmt:
	@packer fmt -check main.pkr.hcl

.PHONY: clean
clean:
	@rm -rf output-debian12

.PHONY: validate
validate:
	packer validate main.pkr.hcl

.PHONY: build
build:
	@packer build main.pkr.hcl

.PHONY: debug-v1
debug-v1:
	@PACKER_LOG=1 PACKER_LOG_PATH=../../.tmp/debug-v1.log make build 2>&1 | tee ../../.tmp/build-v1.log

.PHONY: debug-v2
debug-v2:
	@PACKER_LOG=1 PACKER_LOG_PATH=../../.tmp/debug-v2.log make build 2>&1 | tee ../../.tmp/build-v2.log

.PHONY: login-provisioner
login-provisioner:
	@ssh -p 2222 -o PubkeyAuthentication=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $(PROVISIONER_USERNAME)@127.0.0.1

.PHONY: login-guest
login-guest:
	@ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $(GUEST_USERNAME)@127.0.0.1
