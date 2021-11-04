gitlab_pages_clone_dir = gitlab-pages
gitlab_pages_version = $(shell support/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_PAGES_VERSION")
gitlab_pages_bin_cached_version = ${gitlab_development_cache_root}/.gitlab_pages_bin_${gitlab_pages_version}

################################################################################
# Main
#
.PHONY: gitlab-pages
gitlab-pages: gitlab-pages-setup

################################################################################
# Setup/update/fresh
#
.PHONY: gitlab-pages-setup gitlab-pages-update gitaly-fresh
ifeq ($(gitlab_pages_enabled),true)
gitlab-pages-setup: gitlab-pages-pre-tasks ${gitlab_pages_clone_dir}/.git gitlab-pages-post-tasks

gitlab-pages-update: gitlab-pages-pre-tasks gitlab-pages-git-pull gitlab-pages-post-tasks

gitlab-pages-fresh: gitlab-pages-clean gitlab-pages-update
else
gitlab-pages-setup:
	@true

gitlab-pages-update:
	@true

gitlab-pages-fresh:
	@true
endif

################################################################################
# Pre/post tasks
#
.PHONY: gitlab-pages-pre-tasks
gitlab-pages-pre-tasks: gitlab-pages-inform gitlab-pages-secret

.PHONY: gitlab-pages-post-tasks
gitlab-pages-post-tasks: gitlab-pages-build gitlab-pages/gitlab-pages.conf

################################################################################
# Git
#
${gitlab_pages_clone_dir}/.git:
	$(Q)support/component-git-update gitlab_pages "${gitlab_pages_clone_dir}" "${gitlab_pages_version}" master ${git_depth_param}

gitlab-pages-git-pull:
	$(Q)support/component-git-update gitlab_pages "${gitlab_pages_clone_dir}" "${gitlab_pages_version}" master

################################################################################
# Files
#
gitlab-pages-secret:
	$(Q)rake $@

.PHONY: gitlab-pages/gitlab-pages.conf
gitlab-pages/gitlab-pages.conf: ${gitlab_pages_clone_dir}/.git
	$(Q)rake $@

################################################################################
# Inform
#
.PHONY: gitlab-pages-inform
gitlab-pages-inform:
	@echo
	@echo "${DIVIDER}"
	@echo "gitlab-pages: Updating git repo to ${gitlab_pages_version}"
	@echo "${DIVIDER}"

.PHONY: gitlab-pages-inform-build
gitlab-pages-inform-build:
	@echo
	@echo "${DIVIDER}"
	@echo "gitlab-pages: Building ${gitlab_pages_version}"
	@echo "${DIVIDER}"

################################################################################
# Clean
#
.PHONY: gitlab-pages-clean
gitlab-pages-clean:
	$(Q)rm -rf ${gitlab_development_cache_root}/.gitlab_pages_* gitlab-pages/bin/gitlab-pages

################################################################################

.PHONY: gitlab-pages-build
gitlab-pages-build: gitlab-pages-inform-build ${gitlab_pages_bin_cached_version}

${gitlab_pages_bin_cached_version}:
	$(Q)$(MAKE) -C ${gitlab_pages_clone_dir} ${QQ}
	$(Q)touch $@
