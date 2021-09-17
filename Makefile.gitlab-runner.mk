runner-setup: gitlab-runner-config.toml

.PHONY: gitlab-runner-config.toml
ifeq ($(runner_enabled),true)
gitlab-runner-config.toml:
	$(Q)rake $@
else
gitlab-runner-config.toml:
	@true
endif
