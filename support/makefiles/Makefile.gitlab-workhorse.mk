workhorse_dir = ${gitlab_development_root}/gitlab/workhorse

ifeq ($(workhorse_skip_setup),true)
gitlab-workhorse-setup:
	@echo
	@echo "${DIVIDER}"
	@echo "Skipping gitlab-workhorse setup due to option workhorse.skip_setup set to true"
	@echo "${DIVIDER}"
else
gitlab-workhorse-setup: gitlab-workhorse-asdf-install gitlab/workhorse/gitlab-workhorse gitlab/workhorse/config.toml
endif

.PHONY: gitlab-workhorse-update
gitlab-workhorse-update: gitlab-workhorse-update-timed

.PHONY: gitlab-workhorse-run
gitlab-workhorse-update-run: gitlab-workhorse-clean-bin gitlab/workhorse/config.toml gitlab-workhorse-setup

gitlab-workhorse-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${workhorse_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${workhorse_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${workhorse_dir}/.tool-versions" asdf install
	$(Q)cd ${workhorse_dir} && asdf reshim
else
	@true
endif

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
