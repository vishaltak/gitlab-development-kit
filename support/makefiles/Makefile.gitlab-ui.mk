gitlab_ui_clone_dir = gitlab-ui

.PHONY: gitlab-ui-setup
ifeq ($(gitlab_ui_enabled),true)
gitlab-ui-setup: gitlab-ui/.git .gitlab-ui-yarn
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
gitlab-ui-update-run: gitlab-ui/.git gitlab-ui/.git/pull gitlab-ui-clean .gitlab-ui-yarn

gitlab-ui/.git:
	$(Q)support/component-git-update gitlab_ui "${gitlab_ui_clone_dir}" main main ${git_depth_param}

gitlab-ui/.git/pull:
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-ui"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab_ui "${gitlab_ui_clone_dir}" main main

.PHONY: gitlab-ui-clean
gitlab-ui-clean:
	@rm -f .gitlab-ui-yarn

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
