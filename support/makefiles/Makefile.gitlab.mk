gitlab_clone_dir = gitlab
gitlab_rake_cmd = $(in_gitlab) ${support_bundle_exec} rake
gitlab_git_cmd = git -C $(gitlab_development_root)/$(gitlab_clone_dir)
in_gitlab = cd $(gitlab_development_root)/$(gitlab_clone_dir) &&
bundle_without_production_cmd = ${BUNDLE} config --local set without 'production'
# default_branch ?= $(if $(gitlab_default_branch),$(gitlab_default_branch),master)
default_branch ?= 54b04eb93b35b863d3fa07a2e508f33269b5c91c

gitlab-setup: gitlab/.git gitlab-config .gitlab-bundle .gitlab-gdk-gem .gitlab-lefthook .gitlab-yarn .gitlab-translations

.PHONY: gitlab-update
gitlab-update: gitlab-update-timed

.PHONY: gitlab-update-run
gitlab-update-run: \
	gitlab-git-pull \
	gitlab-config \
	postgresql \
	gitlab-setup \
	gitlab-db-migrate \
	gitlab/doc/api/graphql/reference/gitlab_schema.json

.PHONY: gitlab/git-checkout-auto-generated-files
gitlab/git-checkout-auto-generated-files:
	$(Q)support/retry-command '$(gitlab_git_cmd) ls-tree HEAD --name-only -- Gemfile.lock db/structure.sql db/schema.rb ee/db/geo/structure.sql ee/db/geo/schema.rb | xargs $(gitlab_git_cmd) checkout --'

gitlab/doc/api/graphql/reference/gitlab_schema.json: .gitlab-bundle
	@echo
	@echo "${DIVIDER}"
	@echo "Generating gitlab GraphQL schema files"
	@echo "${DIVIDER}"
	$(Q)$(gitlab_rake_cmd) gitlab:graphql:schema:dump ${QQ}

.PHONY: gitlab-git-pull
gitlab-git-pull: gitlab-git-pull-timed

.PHONY: gitlab-git-pull-run
gitlab-git-pull-run: gitlab/.git/pull

gitlab/.git/pull: gitlab/git-checkout-auto-generated-files
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab "${gitlab_clone_dir}" $(default_branch) master

gitlab/.git:
	@echo
	@echo "${DIVIDER}"
	@echo "Cloning gitlab-org/gitlab"
	@echo "${DIVIDER}"
	$(Q)support/component-git-clone ${git_params} $(if $(realpath ${gitlab_repo}),--shared) ${gitlab_repo} ${gitlab_clone_dir}

gitlab-config: \
	touch-examples \
	gitlab/config/gitlab.yml \
	gitlab/config/database.yml \
	gitlab/config/cable.yml \
	gitlab/config/resque.yml \
	gitlab/config/redis.cache.yml \
	gitlab/config/redis.repository_cache.yml \
	gitlab/config/redis.queues.yml \
	gitlab/config/redis.shared_state.yml \
	gitlab/config/redis.trace_chunks.yml \
	gitlab/config/redis.rate_limiting.yml \
	gitlab/config/redis.sessions.yml \
	gitlab/public/uploads \
	gitlab/config/puma.rb

gitlab/public/uploads:
	$(Q)mkdir $@

.PHONY: gitlab-bundle-prepare
gitlab-bundle-prepare:
	@echo
	@echo "${DIVIDER}"
	@echo "Setting up Ruby bundler"
	@echo "${DIVIDER}"
	$(Q)$(in_gitlab) $(bundle_without_production_cmd) ${QQ}
	${Q}. ./support/bootstrap-common.sh ; configure_ruby_bundler_for_gitlab

.gitlab-bundle: gitlab-bundle-prepare
	@echo
	@echo "${DIVIDER}"
	@echo "Installing gitlab-org/gitlab Ruby gems"
	@echo "${DIVIDER}"
	${Q}$(support_bundle_install) $(gitlab_development_root)/$(gitlab_clone_dir)
	$(Q)touch $@

.gitlab-gdk-gem:
	@echo
	@echo "${DIVIDER}"
	@echo "Installing the gitlab-development-kit gem"
	@echo "${DIVIDER}"
	${Q}. ./support/bootstrap-common.sh ; gdk_install_gem

ifeq ($(gitlab_lefthook_enabled),true)
.gitlab-lefthook:
	@echo
	@echo "${DIVIDER}"
	@echo "Enabling Lefthook for gitlab-org/gitlab"
	@echo "${DIVIDER}"
	$(Q)$(in_gitlab) ${support_bundle_exec} lefthook install
	$(Q)touch $@
else
.gitlab-lefthook:
	@true
endif

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
