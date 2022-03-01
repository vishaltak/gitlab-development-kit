.PHONY: registry-setup
registry-setup:
	${Q}support/modules/registry setup

.PHONY: trust-docker-registry
trust-docker-registry:
	${Q}support/modules/registry trust
