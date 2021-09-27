gitlab_shell_clone_dir = gitlab-shell
gitlab_shell_version = $(shell support/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_SHELL_VERSION")

gitlab-shell-setup: ${gitlab_shell_clone_dir}/.git gitlab-shell/config.yml .gitlab-shell-bundle gitlab-shell/.gitlab_shell_secret openssh/ssh_host_rsa_key
	$(Q)make -C gitlab-shell build ${QQ}

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
	$(Q)support/component-git-update gitlab_shell "${gitlab_development_root}/gitlab-shell" "${gitlab_shell_version}"

# This task is phony to allow
# support/move-existing-gitlab-shell-directory to remove the legacy
# symlink, if necessary. See https://gitlab.com/gitlab-org/gitlab-development-kit/-/merge_requests/1086
.PHONY: ${gitlab_shell_clone_dir}/.git
${gitlab_shell_clone_dir}/.git:
	$(Q)support/move-existing-gitlab-shell-directory || support/component-git-clone --quiet --branch "${gitlab_shell_version}" ${git_depth_param} ${gitlab_shell_repo} ${gitlab_shell_clone_dir}

.PHONY: gitlab-shell/config.yml
gitlab-shell/config.yml: ${gitlab_shell_clone_dir}/.git
	$(Q)rake $@

.gitlab-shell-bundle:
	$(Q)cd ${gitlab_development_root}/gitlab-shell && $(bundle_install_cmd)
	$(Q)touch $@

gitlab-shell/.gitlab_shell_secret:
	$(Q)ln -nfs ${gitlab_development_root}/gitlab/.gitlab_shell_secret $@
