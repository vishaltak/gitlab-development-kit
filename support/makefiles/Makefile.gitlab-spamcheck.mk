gitlab_spamcheck_clone_dir = gitlab-spamcheck
gitlab_spamcheck_version = main
gitlab_spamcheck_bin_cached_version = ${gitlab_development_cache_root}/.gitlab_spamcheck_bin_${gitlab_spamcheck_version}

################################################################################
# Main
#
.PHONY: gitlab-spamcheck
gitlab-spamcheck: gitlab-spamcheck-setup

.PHONY: gitlab-spamcheck-setup gitlab-spamcheck-update gitlab-spamcheck-fresh
ifeq ($(gitlab_spamcheck_enabled),true)
gitlab-spamcheck-setup: gitlab-spamcheck-pre-tasks ${gitlab_spamcheck_clone_dir}/.git gitlab-spamcheck-post-tasks

gitlab-spamcheck-update: gitlab-spamcheck-pre-tasks gitlab-spamcheck-git-pull gitlab-spamcheck-cache-clean gitlab-spamcheck-post-tasks

gitlab-spamcheck-fresh: gitlab-spamcheck-clean gitlab-spamcheck-update
else
gitlab-spamcheck-setup:
	@true

gitlab-spamcheck-update:
	@true
endif

################################################################################
# Pre/post tasks
#
.PHONY: gitlab-spamcheck-pre-tasks
gitlab-spamcheck-pre-tasks: gitlab-spamcheck-inform

.PHONY: gitlab-spamcheck-post-tasks
gitlab-spamcheck-post-tasks: gitlab-spamcheck-inform-build ${gitlab_spamcheck_bin_cached_version} gitlab-spamcheck/config/config.toml

################################################################################
# Git
#
${gitlab_spamcheck_clone_dir}/.git:
	$(Q)support/component-git-update gitlab_spamcheck "${gitlab_spamcheck_clone_dir}" main main ${git_depth_param}

.PHONY: gitlab-spamcheck-git-pull
gitlab-spamcheck-git-pull:
	$(Q)support/component-git-update gitlab_spamcheck "${gitlab_spamcheck_clone_dir}" main main

################################################################################
# Files
#
.PHONY: gitlab-spamcheck/config/config.toml
gitlab-spamcheck/config/config.toml:
	$(Q)rake $@

################################################################################
# Inform
#
.PHONY: gitlab-spamcheck-inform
gitlab-spamcheck-inform:
	@echo
	@echo "${DIVIDER}"
	@echo "gitlab-spamcheck: Updating git repo to ${gitlab_spamcheck_version}"
	@echo "${DIVIDER}"

.PHONY: gitlab-spamcheck-inform-build
gitlab-spamcheck-inform-build:
	@echo
	@echo "${DIVIDER}"
	@echo "gitlab-spamcheck: Building ${gitlab_spamcheck_version}"
	@echo "${DIVIDER}"

################################################################################
# Clean
#
.PHONY: gitlab-spamcheck-cache-clean
gitlab-spamcheck-cache-clean:
	$(Q)rm -rf ${gitlab_development_cache_root}/.gitlab_spamcheck_*

.PHONY: gitlab-spamcheck-clean
gitlab-spamcheck-clean: gitlab-spamcheck-cache-clean
	$(Q)rm -rf gitlab-spamcheck/bin/gitlab-spamcheck

################################################################################

.PHONY: gitlab-spamcheck-build
gitlab-spamcheck-build: gitlab-spamcheck-inform-build ${gitlab_spamcheck_bin_cached_version}

${gitlab_spamcheck_bin_cached_version}:
	$(Q)make -C gitlab-spamcheck build ${QQ}
	$(Q)touch $@
