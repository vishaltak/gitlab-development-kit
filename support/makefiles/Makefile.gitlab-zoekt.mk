gitlab_zoekt_indexer_dir = ${gitlab_development_root}/gitlab-zoekt-indexer

.PHONY: gitlab-zoekt-indexer-setup
ifeq ($(zoekt_enabled),true)
gitlab-zoekt-indexer-setup: gitlab-zoekt-indexer/.git/pull gitlab-zoekt-indexer/bin/gitlab-zoekt-indexer
else
gitlab-zoekt-indexer-setup:
	@true
endif

.PHONY: gitlab-zoekt-indexer-update
ifeq ($(zoekt_enabled),true)
gitlab-zoekt-indexer-update: gitlab-zoekt-indexer-update-timed
else
gitlab-zoekt-indexer-update:
	@true
endif

.PHONY: gitlab-zoekt-indexer-update-run
gitlab-zoekt-indexer-update-run: gitlab-zoekt-indexer/.git/pull gitlab-zoekt-indexer-clean-bin gitlab-zoekt-indexer/bin/gitlab-zoekt-indexer

gitlab-zoekt-indexer-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${gitlab_zoekt_indexer_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${gitlab_zoekt_indexer_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${gitlab_zoekt_indexer_dir}/.tool-versions" asdf install
	$(Q)cd ${gitlab_zoekt_indexer_dir} && asdf reshim
else
	@true
endif

gitlab-zoekt-indexer-clean-bin:
	$(Q)rm -rf gitlab-zoekt-indexer/bin/*

gitlab-zoekt-indexer/.git:
	$(Q)GIT_REVISION="${gitlab_zoekt_indexer_version}" support/component-git-clone ${git_params} ${gitlab_zoekt_indexer_repo} gitlab-zoekt-indexer

.PHONY: gitlab-zoekt-indexer/bin/gitlab-zoekt-indexer
gitlab-zoekt-indexer/bin/gitlab-zoekt-indexer: gitlab-zoekt-indexer-asdf-install
	@echo
	@echo "${DIVIDER}"
	@echo "Building gitlab-org/gitlab-zoekt-indexer version ${gitlab_zoekt_indexer_version}"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec gitlab-zoekt-indexer $(MAKE) build ${QQ}

.PHONY: gitlab-zoekt-indexer/.git/pull
gitlab-zoekt-indexer/.git/pull: gitlab-zoekt-indexer/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-zoekt-indexer"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update zoekt gitlab-zoekt-indexer "${gitlab_zoekt_indexer_version}" main
