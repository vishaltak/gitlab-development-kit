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
	$(Q)support/component-git-clone --quiet --branch "${gitlab_elasticsearch_indexer_version}" ${git_depth_param} ${gitlab_elasticsearch_indexer_repo} gitlab-elasticsearch-indexer

.PHONY: gitlab-elasticsearch-indexer/bin/gitlab-elasticsearch-indexer
gitlab-elasticsearch-indexer/bin/gitlab-elasticsearch-indexer: gitlab-elasticsearch-indexer/.git
	$(Q)$(MAKE) -C gitlab-elasticsearch-indexer build ${QQ}

.PHONY: gitlab-elasticsearch-indexer/.git/pull
gitlab-elasticsearch-indexer/.git/pull: gitlab-elasticsearch-indexer/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-elasticsearch-indexer to ${gitlab_elasticsearch_indexer_version}"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab_elasticsearch_indexer gitlab-elasticsearch-indexer "${gitlab_elasticsearch_indexer_version}"
