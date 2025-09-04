PKGNAME := foreman_scap_client_bash

ifeq ($(origin VERSION), undefined)
	VERSION := 0.2.1
endif

test:
	@echo "Running foreman_scap_client_bash tests..."
	@./test/test_config_parser.sh config-simple.yaml
	@./test/test_config_parser.sh config-tricky.yaml

dist-tar:
	tar --create \
		--gzip \
		--file /tmp/$(PKGNAME)-$(VERSION).tar.gz \
		--exclude=.git \
		--exclude=.vscode \
		--exclude=.github \
		--exclude=.gitignore \
		--exclude=.copr \
		--exclude=test \
		--transform s/^\./$(PKGNAME)-$(VERSION)/ \
		. && mv /tmp/$(PKGNAME)-$(VERSION).tar.gz .

.PHONY: test
