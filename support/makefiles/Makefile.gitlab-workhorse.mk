ifeq ($(SKIP_WORKHORSE_SETUP),true)
gitlab-workhorse-setup:
	@echo
	@echo "${DIVIDER}"
	@echo "Skipping gitlab-workhorse setup due to environment variable SKIP_WORKHORSE_SETUP set to true"
	@echo "${DIVIDER}"
else
gitlab-workhorse-setup: gitlab/workhorse/gitlab-workhorse gitlab/workhorse/config.toml
endif

.PHONY: gitlab-workhorse-update
gitlab-workhorse-update: gitlab-workhorse-update-timed

.PHONY: gitlab-workhorse-run
gitlab-workhorse-update-run: gitlab-workhorse-clean-bin gitlab/workhorse/config.toml gitlab-workhorse-setup

.PHONY: gitlab-workhorse-compile
gitlab-workhorse-compile:
	@echo
	@echo "${DIVIDER}"
	@echo "Compiling gitlab/workhorse/gitlab-workhorse"
	@echo "${DIVIDER}"

gitlab-workhorse-clean-bin: gitlab-workhorse-compile
	$(Q)support/asdf-exec gitlab/workhorse $(MAKE) clean

.PHONY: gitlab/workhorse/gitlab-workhorse
gitlab/workhorse/gitlab-workhorse: gitlab-workhorse-compile
	$(Q)support/asdf-exec gitlab/workhorse $(MAKE) ${QQ}
