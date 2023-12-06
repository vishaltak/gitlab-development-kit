gitlab_shell_clone_dir = gitlab-shell
gitlab_shell_dir = ${gitlab_development_root}/${gitlab_shell_clone_dir}
gitlab_shell_version = $(shell support/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_SHELL_VERSION")

ifeq ($(gitlab_shell_skip_setup),true)
gitlab-shell-setup:
	@echo
	@echo "${DIVIDER}"
	@echo "Skipping gitlab-shell setup due to option gitlab_shell.skip_setup set to true"
	@echo "${DIVIDER}"
else
gitlab-shell-setup: gitlab-shell/.git gitlab-shell/config.yml gitlab-shell-deps gitlab-shell/.gitlab_shell_secret $(sshd_hostkeys)
	$(Q)make -C gitlab-shell build ${QQ}
endif

.PHONY: gitlab-shell-update
gitlab-shell-update: gitlab-shell-update-timed

.PHONY: gitlab-shell-update-run
gitlab-shell-update-run: gitlab-shell-git-pull gitlab-shell-setup

.PHONY: gitlab-shell-git-pull
gitlab-shell-git-pull: gitlab-shell-git-pull-timed

.PHONY: gitlab-shell-git-pull-run
gitlab-shell-git-pull-run:
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-shell to ${gitlab_shell_version}"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab_shell "${gitlab_development_root}/gitlab-shell" "${gitlab_shell_version}" main

# This task is phony to allow
# support/move-existing-gitlab-shell-directory to remove the legacy
# symlink, if necessary. See https://gitlab.com/gitlab-org/gitlab-development-kit/-/merge_requests/1086
.PHONY: ${gitlab_shell_clone_dir}/.git
gitlab-shell/.git:
	$(Q)support/move-existing-gitlab-shell-directory || GIT_REVISION="${gitlab_shell_version}" support/component-git-clone ${git_params} ${gitlab_shell_repo} ${gitlab_shell_clone_dir}

.gitlab-shell-bundle:
	@echo
	@echo "${DIVIDER}"
	@echo "Installing gitlab-org/gitlab-shell Ruby gems"
	@echo "${DIVIDER}"
	${Q}$(support_bundle_install) $(gitlab_shell_dir)
	$(Q)touch $@

.PHONY: gitlab-shell/.gitlab_shell_secret
gitlab-shell/.gitlab_shell_secret:
	$(Q)ln -nfs ${gitlab_development_root}/gitlab/.gitlab_shell_secret $@

.PHONY: gitlab-shell-deps
gitlab-shell-deps: gitlab-shell-asdf-install .gitlab-shell-bundle

.PHONY: gitlab-shell-asdf-install
gitlab-shell-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${gitlab_shell_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${gitlab_shell_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${gitlab_shell_dir}/.tool-versions" asdf install
	$(Q)cd ${gitlab_shell_dir} && asdf reshim
else
	@true
endif
