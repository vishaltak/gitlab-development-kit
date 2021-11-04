gitlab_clone_dir = gitlab
gitlab_rake_cmd = $(in_gitlab) ${BUNDLE} exec rake
gitlab_git_cmd = git -C $(gitlab_development_root)/$(gitlab_clone_dir)
in_gitlab = cd $(gitlab_development_root)/$(gitlab_clone_dir) &&
bundle_without_production_cmd = ${BUNDLE} config set without 'production'

################################################################################
# Main
#
.PHONY: gitlab
gitlab: gitlab-setup

################################################################################
# Setup/update/fresh
#
.PHONY: gitlab-setup
gitlab-setup: gitlab-pre-tasks ${gitlab_clone_dir}/.git gitlab-post-tasks

.PHONY: gitlab-setup-minimal
gitlab-setup-minimal: gitlab-inform ${gitlab_clone_dir}/.git gitlab-post-tasks-minimal

.PHONY: gitlab-update
gitlab-update: gitlab-pre-tasks gitlab-git-pull gitlab-post-tasks

.PHONY: gitlab-update-minimal
gitlab-update-minimal: gitlab-inform gitlab-git-pull gitlab-translations-unlock gitlab-post-tasks-minimal

.PHONY: gitlab-update-without-pull
gitlab-update-without-pull: gitlab-pre-tasks gitlab-translations-unlock gitlab-post-tasks

.PHONY: gitlab-fresh
gitlab-fresh: gitlab-clean gitlab-update

################################################################################
# Pre/post tasks
#
.PHONY: gitlab-pre-tasks
gitlab-pre-tasks: gitlab-inform check-if-services-running/db

.PHONY: gitlab-post-tasks-minimal
gitlab-post-tasks-minimal: .gitlab-bundle .gitlab-yarn gitlab-inform-config-update gitlab-config .gitlab-translations

.PHONY: gitlab-post-tasks
gitlab-post-tasks: gitlab-post-tasks-minimal gitlab-db-bootstrap-rails gitlab-db-migrate gitlab/doc/api/graphql/reference/gitlab_schema.json

################################################################################
# Git
#
${gitlab_clone_dir}/.git:
	$(Q)support/component-git-update gitlab "${gitlab_clone_dir}" master master ${git_depth_param} $(if $(realpath ${gitlab_repo}),--shared)

.PHONY: gitlab-git-pull
gitlab-git-pull: gitlab/git-checkout-auto-generated-files
	$(Q)support/component-git-update gitlab "${gitlab_clone_dir}" master master

################################################################################
# Files
#
.PHONY: gitlab-config
gitlab-config: \
	gitlab/.gitlab_shell_secret \
	gitlab/config/gitlab.yml \
	gitlab/config/database.yml \
	gitlab/config/cable.yml \
	gitlab/config/resque.yml \
	gitlab/config/redis.cache.yml \
	gitlab/config/redis.queues.yml \
	gitlab/config/redis.shared_state.yml \
	gitlab/config/redis.trace_chunks.yml \
	gitlab/config/redis.rate_limiting.yml \
	gitlab/config/redis.sessions.yml \
	gitlab/public/uploads \
	gitlab/config/puma.rb

gitlab/.gitlab_shell_secret:
	$(Q)rake $@

.PHONY: gitlab/config/gitlab.yml
gitlab/config/gitlab.yml:
	$(Q)rake $@

.PHONY: gitlab/config/database.yml
gitlab/config/database.yml:
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

.PHONY: gitlab/config/redis.rate_limiting.yml
gitlab/config/redis.rate_limiting.yml:
	$(Q)rake $@

.PHONY: gitlab/config/redis.sessions.yml
gitlab/config/redis.sessions.yml:
	$(Q)rake $@

.PHONY: gitlab/config/puma.rb
gitlab/config/puma.rb:
	$(Q)rake $@

################################################################################
# Inform
#
.PHONY: gitlab-inform
gitlab-inform:
	@echo
	@echo "${DIVIDER}"
	@echo "gitlab-org/gitlab: Updating git repo to latest"
	@echo "${DIVIDER}"

.PHONY: gitlab-inform-config-update
gitlab-inform-config-update:
	@echo
	@echo "${DIVIDER}"
	@echo "gitlab-org/gitlab: Updating configs"
	@echo "${DIVIDER}"

################################################################################
# Clean
#
.PHONY: gitlab-clean
gitlab-clean:

################################################################################

gitlab/doc/api/graphql/reference/gitlab_schema.json: .gitlab-bundle
	@echo
	@echo "${DIVIDER}"
	@echo "gitlab-org/gitlab: Generating Gitlab GraphQL schema files"
	@echo "${DIVIDER}"
	$(Q)$(in_gitlab) bundle exec rake gitlab:graphql:schema:dump ${QQ}

.PHONY: gitlab/git-checkout-auto-generated-files
gitlab/git-checkout-auto-generated-files:
	$(Q)test -d $(gitlab_development_root)/$(gitlab_clone_dir) && (support/retry-command '$(gitlab_git_cmd) ls-tree HEAD --name-only -- Gemfile.lock db/structure.sql db/schema.rb ee/db/geo/structure.sql ee/db/geo/schema.rb | xargs $(gitlab_git_cmd) checkout --')

.PHONY: gitlab-db-bootstrap-rails
gitlab-db-bootstrap-rails: check-if-services-running/rails-migration-dependencies
	@echo
	@echo "${DIVIDER}"
	@echo "gitlab-org/gitlab: Bootstrapping Rails DBs"
	@echo "${DIVIDER}"
	$(Q)support/bootstrap-rails

.PHONY: gitlab-db-migrate
gitlab-db-migrate: check-if-services-running/db
	@echo
	@echo "${DIVIDER}"
	@echo "gitlab-org/gitlab: Processing Rails DB migrations"
	@echo "${DIVIDER}"
	$(Q)rake gitlab_rails:db:migrate

gitlab/public/uploads:
	$(Q)mkdir $@

.gitlab-bundle:
	@echo
	@echo "${DIVIDER}"
	@echo "gitlab-org/gitlab: Installing Ruby gems"
	@echo "${DIVIDER}"
	$(Q)$(in_gitlab) $(bundle_without_production_cmd) ${QQ}
	${Q}. ./support/bootstrap-common.sh ; configure_ruby_bundler
	$(Q)$(in_gitlab) $(bundle_install_cmd)
	$(Q)touch $@

.gitlab-yarn:
	@echo
	@echo "${DIVIDER}"
	@echo "gitlab-org/gitlab: Installing Node.js packages"
	@echo "${DIVIDER}"
	$(Q)$(in_gitlab) ${YARN} install --pure-lockfile ${QQ}
	$(Q)touch $@

.PHONY: gitlab-translations-unlock
gitlab-translations-unlock:
	$(Q)rm -f .gitlab-translations

.gitlab-translations:
	@echo
	@echo "${DIVIDER}"
	@echo "gitlab-org/gitlab: Generating Rails translations"
	@echo "${DIVIDER}"
	$(Q)$(gitlab_rake_cmd) gettext:compile > ${gitlab_development_root}/gitlab/log/gettext.log
	$(Q)$(gitlab_git_cmd) checkout locale/*/gitlab.po
	$(Q)touch $@
