gitlab-pages-setup: gitlab-pages-secret gitlab-pages/gitlab-pages.conf gitlab-pages/bin/gitlab-pages

gitlab-pages-secret:
	$(Q)rake $@

.PHONY: gitlab-pages/gitlab-pages.conf
gitlab-pages/gitlab-pages.conf: ${gitlab_pages_clone_dir}/.git
	$(Q)rake $@

.PHONY: gitlab-pages-update
gitlab-pages-update: gitlab-pages-update-timed

.PHONY: gitlab-pages-update-run
gitlab-pages-update-run: ${gitlab_pages_clone_dir}/.git gitlab-pages/.git/pull gitlab-pages-clean-bin gitlab-pages/bin/gitlab-pages gitlab-pages/gitlab-pages.conf

gitlab-pages-clean-bin:
	$(Q)rm -f gitlab-pages/bin/gitlab-pages

.PHONY: gitlab-pages/bin/gitlab-pages
gitlab-pages/bin/gitlab-pages: ${gitlab_pages_clone_dir}/.git
	$(Q)$(MAKE) -C ${gitlab_pages_clone_dir} ${QQ}

${gitlab_pages_clone_dir}/.git:
	$(Q)support/move-existing-gitlab-pages-directory || support/component-git-clone --quiet --branch "${pages_version}" ${git_depth_param} ${gitlab_pages_repo} ${gitlab_pages_clone_dir} ${QQ}

gitlab-pages/.git/pull:
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-pages to ${pages_version}"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab_pages "${gitlab_pages_clone_dir}" "${pages_version}"
