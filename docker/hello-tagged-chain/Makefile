.PHONY: clean
clean:
	@rm -rf .tmp

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
build: clean
	@mkdir -p .tmp
	@packer build main.pkr.hcl

.PHONY: sha256
sha256:
	@cat .tmp/hello-tagged-chain.tar.sha256
	@(cd .tmp && sha256sum -c hello-tagged-chain.tar.sha256)

.PHONY: load
load:
	@docker rmi hello-tagged-chain:latest || true
	@docker load -i .tmp/hello-tagged-chain.tar

.PHONY: run
run:
	@docker run --rm hello-tagged-chain:latest sh -c 'cat /tmp/hello.txt && tree --version'
