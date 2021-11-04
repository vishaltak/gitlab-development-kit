gitlab_shell_clone_dir = gitlab-shell
gitlab_shell_version = $(shell support/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_SHELL_VERSION")
gitlab_shell_bin_cached_version = ${gitlab_development_cache_root}/.gitlab_shell_${gitlab_shell_version}

################################################################################
# Main
#
gitlab-shell: gitlab-shell-setup

################################################################################
# Setup/update/fresh
#
.PHONY: gitlab-shell-setup
gitlab-shell-setup: gitlab-shell-pre-tasks ${gitlab_shell_clone_dir}/.git gitlab-shell-post-tasks

.PHONY: gitlab-shell-update
gitlab-shell-update: gitlab-shell-pre-tasks gitlab-shell-git-pull gitlab-shell-post-tasks

.PHONY: gitlab-shell-fresh
gitlab-shell-fresh: gitlab-shell-clean gitlab-shell-update

################################################################################
# Pre/post tasks
#
.PHONY: gitlab-shell-pre-tasks
gitlab-shell-pre-tasks: gitlab-shell-inform

.PHONY: gitlab-shell-post-tasks
gitlab-shell-post-tasks: gitlab-shell/config.yml gitlab-shell/.gitlab_shell_secret openssh/ssh_host_rsa_key gitlab-shell-bundle gitlab-shell-build

################################################################################
# Git
#
${gitlab_shell_clone_dir}/.git:
	$(Q)support/component-git-update gitlab_shell "${gitlab_development_root}/gitlab-shell" "${gitlab_shell_version}" main ${git_depth_param}

.PHONY: gitlab-shell-git-pull
gitlab-shell-git-pull:
	$(Q)support/component-git-update gitlab_shell "${gitlab_development_root}/gitlab-shell" "${gitlab_shell_version}" main

################################################################################
# Files
#
${gitlab_shell_bin_cached_version}:
	$(Q)make -C gitlab-shell build ${QQ}
	@mkdir -p ${gitlab_development_cache_root}
	$(Q)touch $@

.PHONY: gitlab-shell-bundle
gitlab-shell-bundle:
	$(Q)cd ${gitlab_development_root}/gitlab-shell && $(bundle_install_cmd)

.PHONY: gitlab-shell/config.yml
gitlab-shell/config.yml:
	$(Q)rake $@

.PHONY: gitlab-shell/.gitlab_shell_secret
# Ensure it's _always_ (re)created
gitlab-shell/.gitlab_shell_secret: gitlab/.gitlab_shell_secret
	$(Q)ln -nfs ${gitlab_development_root}/gitlab/.gitlab_shell_secret $@

################################################################################
# Inform
#
.PHONY: gitlab-shell-inform
gitlab-shell-inform:
	@echo
	@echo "${DIVIDER}"
	@echo "gitlab-shell: Updating git repo to ${gitlab_shell_version}"
	@echo "${DIVIDER}"

.PHONY: gitlab-shell-inform-build
gitlab-shell-inform-build:
	@echo
	@echo "${DIVIDER}"
	@echo "gitlab-shell: Building ${gitlab_shell_version}"
	@echo "${DIVIDER}"

################################################################################
# Clean
#
.PHONY: gitlab-shell-clean
gitlab-shell-clean:
	@rm -f ${gitlab_development_cache_root}/.gitlab_shell_* rm -f gitlab-shell/bin/* gitlab-shell/.gitlab_shell_secret

################################################################################

.PHONY: gitlab-shell-build
gitlab-shell-build: gitlab-shell-inform-build ${gitlab_shell_bin_cached_version}
