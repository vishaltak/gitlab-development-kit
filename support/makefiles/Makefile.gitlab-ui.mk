gitlab_ui_dir = ${gitlab_development_root}/gitlab-ui

.PHONY: gitlab-ui-setup
ifeq ($(gitlab_ui_enabled),true)
gitlab-ui-setup: gitlab-ui/.git gitlab-ui-asdf-install .gitlab-ui-yarn
else
gitlab-ui-setup:
	@true
endif

.PHONY: gitlab-ui-update
ifeq ($(gitlab_ui_enabled),true)
gitlab-ui-update: gitlab-ui-update-timed
else
gitlab-ui-update:
	@true
endif

.PHONY: gitlab-ui-update-run
gitlab-ui-update-run: gitlab-ui/.git gitlab-ui/.git/pull gitlab-ui-clean gitlab-ui-asdf-install .gitlab-ui-yarn

gitlab-ui/.git:
	$(Q)support/component-git-clone ${git_params} ${gitlab_ui_repo} ${gitlab_ui_dir} ${QQ}

gitlab-ui/.git/pull:
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-ui"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab_ui "${gitlab_ui_dir}" main main

.PHONY: gitlab-ui-clean
gitlab-ui-clean:
	@rm -f .gitlab-ui-yarn

gitlab-ui-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${gitlab_ui_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${gitlab_ui_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${gitlab_ui_dir}/.tool-versions" asdf install
	$(Q)cd ${gitlab_ui_dir} && asdf reshim
else
	@true
endif

.gitlab-ui-yarn:
ifeq ($(YARN),)
	@echo "ERROR: YARN is not installed, please ensure you've bootstrapped your machine. See https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/index.md for more details"
	@false
else
	@echo
	@echo "${DIVIDER}"
	@echo "Installing gitlab-org/gitlab-ui Node.js packages"
	@echo "${DIVIDER}"
	$(Q)cd ${gitlab_development_root}/gitlab-ui && ${YARN} install --silent ${QQ}
	$(Q)cd ${gitlab_development_root}/gitlab-ui && ${YARN} build --silent ${QQ}
	$(Q)touch $@
endif
