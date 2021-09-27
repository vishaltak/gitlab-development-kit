gitlab_clone_dir = gitlab
gitlab_rake_cmd = $(in_gitlab) ${BUNDLE} exec rake
gitlab_git_cmd = git -C $(gitlab_development_root)/$(gitlab_clone_dir)
in_gitlab = cd $(gitlab_development_root)/$(gitlab_clone_dir) &&
bundle_without_production_cmd = ${BUNDLE} config set without 'production'

gitlab-setup: gitlab/.git gitlab-config .gitlab-bundle .gitlab-yarn .gitlab-translations

.PHONY: gitlab-update
gitlab-update: gitlab-update-timed

.PHONY: gitlab-update-run
gitlab-update-run: ensure-databases-running postgresql gitlab-git-pull gitlab-setup gitlab-db-migrate gitlab/doc/api/graphql/reference/gitlab_schema.json

.PHONY: gitlab/git-restore
gitlab/git-restore:
	$(Q)$(gitlab_git_cmd) ls-tree HEAD --name-only -- Gemfile.lock db/structure.sql db/schema.rb ee/db/geo/schema.rb | xargs $(gitlab_git_cmd) checkout --

gitlab/doc/api/graphql/reference/gitlab_schema.json: .gitlab-bundle
	@echo
	@echo "${DIVIDER}"
	@echo "Generating gitlab GraphQL schema files"
	@echo "${DIVIDER}"
	$(Q)$(in_gitlab) bundle exec rake gitlab:graphql:schema:dump ${QQ}

.PHONY: gitlab-git-pull
gitlab-git-pull: gitlab-git-pull-timed

.PHONY: gitlab-git-pull-run
gitlab-git-pull-run: gitlab/.git/pull

gitlab/.git/pull: gitlab/git-restore
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab to current default branch"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab "${gitlab_clone_dir}" HEAD false ${QQ}

.PHONY: gitlab-db-migrate
gitlab-db-migrate: ensure-databases-running
	@echo
	$(Q)rake gitlab_rails:db:migrate

gitlab/.git:
	$(Q)support/component-git-clone ${git_depth_param} ${gitlab_repo} ${gitlab_clone_dir} $(if $(realpath ${gitlab_repo}),--shared)

gitlab-config: \
	gitlab/config/gitlab.yml \
	gitlab/config/database.yml \
	gitlab/config/cable.yml \
	gitlab/config/resque.yml \
	gitlab/config/redis.cache.yml \
	gitlab/config/redis.queues.yml \
	gitlab/config/redis.shared_state.yml \
	gitlab/config/redis.trace_chunks.yml \
	gitlab/public/uploads \
	gitlab/config/puma.rb

.PHONY: gitlab/config/gitlab.yml
gitlab/config/gitlab.yml:
	$(Q)rake $@

.PHONY: gitlab/config/database.yml
gitlab/config/database.yml:
	$(Q)rake $@

.PHONY: gitlab/config/puma.rb
gitlab/config/puma.rb:
	$(Q)rake $@

.PHONY: gitlab/config/cable.yml
gitlab/config/cable.yml:
	$(Q)rake $@

.PHONY: gitlab/config/resque.yml
gitlab/config/resque.yml:
	$(Q)rake $@

.PHONY: gitlab/config/redis.cache.yml
gitlab/config/redis.cache.yml:
	$(Q)rake $@

.PHONY: gitlab/config/redis.queues.yml
gitlab/config/redis.queues.yml:
	$(Q)rake $@

.PHONY: gitlab/config/redis.shared_state.yml
gitlab/config/redis.shared_state.yml:
	$(Q)rake $@

.PHONY: gitlab/config/redis.trace_chunks.yml
gitlab/config/redis.trace_chunks.yml:
	$(Q)rake $@

gitlab/public/uploads:
	$(Q)mkdir $@

.gitlab-bundle: ensure-required-ruby-bundlers-installed
	@echo
	@echo "${DIVIDER}"
	@echo "Installing gitlab-org/gitlab Ruby gems"
	@echo "${DIVIDER}"
	$(Q)$(in_gitlab) $(bundle_without_production_cmd) ${QQ}
	$(Q)$(in_gitlab) $(bundle_install_cmd)
	$(Q)touch $@

.gitlab-yarn:
	@echo
	@echo "${DIVIDER}"
	@echo "Installing gitlab-org/gitlab Node.js packages"
	@echo "${DIVIDER}"
	$(Q)$(in_gitlab) ${YARN} install --pure-lockfile ${QQ}
	$(Q)touch $@


.PHONY: gitlab-translations-unlock
gitlab-translations-unlock:
	$(Q)rm -f .gitlab-translations

.PHONY: gitlab-translations
gitlab-translations: gitlab-translations-timed

.PHONY: gitlab-translations-run
gitlab-translations-run: .gitlab-translations

.gitlab-translations:
	@echo
	@echo "${DIVIDER}"
	@echo "Generating gitlab-org/gitlab Rails translations"
	@echo "${DIVIDER}"
	$(Q)$(gitlab_rake_cmd) gettext:compile > ${gitlab_development_root}/gitlab/log/gettext.log
	$(Q)$(gitlab_git_cmd) checkout locale/*/gitlab.po
	$(Q)touch $@
