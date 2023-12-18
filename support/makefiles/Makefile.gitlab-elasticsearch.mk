gitlab_elasticsearch_indexer_dir =  ${gitlab_development_root}/gitlab-elasticsearch-indexer
gitlab_elasticsearch_indexer_version = $(shell support/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_ELASTICSEARCH_INDEXER_VERSION")

ifeq ($(gitlab_elasticsearch_indexer_enabled),true)
gitlab-elasticsearch-indexer-setup: gitlab-elasticsearch-indexer/bin/gitlab-elasticsearch-indexer
else
gitlab-elasticsearch-indexer-setup:
	@true
endif

.PHONY: gitlab-elasticsearch-indexer-update
ifeq ($(gitlab_elasticsearch_indexer_enabled),true)
gitlab-elasticsearch-indexer-update: gitlab-elasticsearch-indexer-update-timed
else
gitlab-elasticsearch-indexer-update:
	@true
endif

.PHONY: gitlab-elasticsearch-indexer-update-run
gitlab-elasticsearch-indexer-update-run: gitlab-elasticsearch-indexer/.git/pull gitlab-elasticsearch-indexer-clean-bin gitlab-elasticsearch-indexer/bin/gitlab-elasticsearch-indexer

gitlab-elasticsearch-indexer-clean-bin:
	$(Q)rm -rf gitlab-elasticsearch-indexer/bin

gitlab-elasticsearch-indexer/.git:
	$(Q)GIT_REVISION="${gitlab_elasticsearch_indexer_version}" support/component-git-clone ${git_params} ${gitlab_elasticsearch_indexer_repo} gitlab-elasticsearch-indexer

.PHONY: gitlab-elasticsearch-indexer/bin/gitlab-elasticsearch-indexer
gitlab-elasticsearch-indexer/bin/gitlab-elasticsearch-indexer: gitlab-elasticsearch-indexer/.git/pull gitlab-elasticsearch-indexer-asdf-install
	@echo
	@echo "${DIVIDER}"
	@echo "Building gitlab-org/gitlab-elasticsearch-indexer version ${gitlab_elasticsearch_indexer_version}"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec gitlab-elasticsearch-indexer $(MAKE) build ${QQ}

.PHONY: gitlab-elasticsearch-indexer/.git/pull
gitlab-elasticsearch-indexer/.git/pull: gitlab-elasticsearch-indexer/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-elasticsearch-indexer"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab_elasticsearch_indexer gitlab-elasticsearch-indexer "${gitlab_elasticsearch_indexer_version}" main

gitlab-elasticsearch-indexer-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${gitlab_elasticsearch_indexer_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${gitlab_elasticsearch_indexer_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${gitlab_elasticsearch_indexer_dir}/.tool-versions" asdf install
	$(Q)cd ${gitlab_elasticsearch_indexer_dir} && asdf reshim
else
	@true
endif
