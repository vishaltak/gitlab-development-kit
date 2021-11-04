gitlab_clone_dir = gitlab
gitlab_workhorse_version = $(shell support/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_WORKHORSE_VERSION")
gitlab_workhorse_bin_cached_version = ${gitlab_development_cache_root}/.gitlab_workhorse_bin_${gitlab_workhorse_version}

################################################################################
# Main
#
.PHONY: gitlab/workhorse
gitlab/workhorse: gitlab-workhorse-setup

################################################################################
# Setup/update/fresh
#
.PHONY: gitlab-workhorse-setup
gitlab-workhorse-setup: gitlab-workhorse-pre-tasks ${gitlab_clone_dir}/.git gitlab-workhorse-post-tasks

.PHONY: gitlab-workhorse-update
gitlab-workhorse-update: gitlab-workhorse-pre-tasks gitlab-workhorse-inform-build gitlab-git-pull gitlab-workhorse-post-tasks

.PHONY: gitlab-workhorse-fresh
gitlab-workhorse-fresh: gitlab-workhorse-clean gitlab-workhorse-update

################################################################################
# Pre/post tasks
#
.PHONY: gitlab-workhorse-pre-tasks
gitlab-workhorse-pre-tasks: gitlab-workhorse-inform

.PHONY: gitlab-workhorse-post-tasks
gitlab-workhorse-post-tasks: ${gitlab_workhorse_bin_cached_version} gitlab/workhorse/config.toml

################################################################################
# Files
#
.PHONY: gitlab/workhorse/config.toml
gitlab/workhorse/config.toml:
	$(Q)rake $@

${gitlab_workhorse_bin_cached_version}:
	$(Q)$(MAKE) -C gitlab/workhorse ${QQ}
	@mkdir -p ${gitlab_development_cache_root}
	$(Q)touch $@

################################################################################
# Inform
#
.PHONY: gitlab-workhorse-inform
gitlab-workhorse-inform:
	@echo
	@echo "${DIVIDER}"
	@echo "gitlab-workhorse: Updating GitLab git repo"
	@echo "${DIVIDER}"

.PHONY: gitlab-workhorse-inform-build
gitlab-workhorse-inform-build:
	@echo
	@echo "${DIVIDER}"
	@echo "gitlab-workhorse: Building ${gitlab_workhorse_version}"
	@echo "${DIVIDER}"

################################################################################
# Clean
#
.PHONY: gitlab-workhorse-clean
gitlab-workhorse-clean:
	@rm -f ${gitlab_development_cache_root}/.gitlab_workhorse_* ${gitlab_development_root}/gitlab/workhorse/gitlab-workhorse
