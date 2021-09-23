gitlab_spamcheck_clone_dir = gitlab-spamcheck

ifeq ($(gitlab_spamcheck_enabled),true)
gitlab-spamcheck-setup: gitlab-spamcheck/.git gitlab-spamcheck/spamcheck gitlab-spamcheck/config/config.toml
else
gitlab-spamcheck-setup:
	@true
endif

gitlab-spamcheck/.git:
	$(Q)support/component-git-clone ${git_depth_param} ${gitlab_spamcheck_repo} ${gitlab_spamcheck_clone_dir}

ifeq ($(gitlab_spamcheck_enabled),true)
gitlab-spamcheck-update: gitlab-spamcheck-update-timed
else
gitlab-spamcheck-update:
	@true
endif

.PHONY: gitlab-spamcheck-update-run
gitlab-spamcheck-update-run: gitlab-spamcheck-git-pull gitlab-spamcheck/spamcheck gitlab-spamcheck/config/config.toml

.PHONY: gitlab-spamcheck-git-pull
gitlab-spamcheck-git-pull: gitlab-spamcheck-git-pull-timed

.PHONY: gitlab-spamcheck-git-pull-run
gitlab-spamcheck-git-pull-run: gitlab-spamcheck/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/spamcheck to current default branch"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab_spamcheck "${gitlab_spamcheck_clone_dir}" HEAD ${QQ}

gitlab-spamcheck/spamcheck: gitlab-spamcheck/.git
	$(Q)make -C gitlab-spamcheck build ${QQ}

.PHONY: gitlab-spamcheck/config/config.toml
gitlab-spamcheck/config/config.toml:
	$(Q)rake $@
