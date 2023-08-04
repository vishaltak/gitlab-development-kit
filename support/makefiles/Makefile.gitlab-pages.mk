gitlab_pages_clone_dir = gitlab-pages
gitlab_pages_version = $(shell support/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_PAGES_VERSION")

ifeq ($(gitlab_pages_enabled),true)
gitlab-pages-setup: gitlab-pages-update-timed
else
gitlab-pages-setup:
	@true
endif

ifeq ($(gitlab_pages_enabled),true)
gitlab-pages-update: gitlab-pages-update-timed
else
gitlab-pages-update:
	@true
endif

.PHONY: gitlab-pages-update-run
gitlab-pages-update-run: gitlab-pages-secret gitlab-pages/gitlab-pages.conf gitlab-pages/bin/gitlab-pages

.PHONY: gitlab-pages/bin/gitlab-pages
gitlab-pages/bin/gitlab-pages: gitlab-pages/.git/pull
	@echo
	@echo "${DIVIDER}"
	@echo "Compiling gitlab-org/gitlab-pages"
	@echo "${DIVIDER}"
	$(Q)rm -f gitlab-pages/bin/gitlab-pages
	$(Q)support/asdf-exec ${gitlab_pages_clone_dir} $(MAKE) ${QQ}

gitlab-pages/.git:
	$(Q)support/move-existing-gitlab-pages-directory || GIT_REVISION="${gitlab_pages_version}" support/component-git-clone ${git_params} ${gitlab_pages_repo} ${gitlab_pages_clone_dir} ${QQ}

gitlab-pages/.git/pull: gitlab-pages/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-pages to ${gitlab_pages_version}"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab_pages "${gitlab_pages_clone_dir}" "${gitlab_pages_version}" master
