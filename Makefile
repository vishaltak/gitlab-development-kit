.NOTPARALLEL:

DIVIDER = "--------------------------------------------------------------------------------"

SHELL = /bin/bash
ASDF := $(shell command -v asdf 2> /dev/null)
RAKE := $(shell command -v rake 2> /dev/null)
VALE := $(shell command -v vale 2> /dev/null)
MARKDOWNLINT := $(shell command -v markdownlint 2> /dev/null)
BUNDLE := $(shell command -v bundle 2> /dev/null)
RUBOCOP := $(shell command -v rubocop 2> /dev/null)
RSPEC := $(shell command -v rspec 2> /dev/null)
SHELLCHECK := $(shell command -v shellcheck 2> /dev/null)
GOLANG := $(shell command -v go 2> /dev/null)
NPM := $(shell command -v npm 2> /dev/null)
YARN := $(shell command -v yarn 2> /dev/null)
REQUIRED_BUNDLER_VERSION := $(shell grep -A1 'BUNDLED WITH' Gemfile.lock | tail -n1 | tr -d ' ')

# Speed up Go module downloads
export GOPROXY ?= https://proxy.golang.org

NO_RUBY_REQUIRED := bootstrap lint

# Generate a Makefile from Ruby and include it
ifdef RAKE
ifeq (,$(filter $(NO_RUBY_REQUIRED), $(MAKECMDGOALS)))
include $(shell rake gdk-config.mk)
endif
endif

ifeq ($(platform),macos)
OPENSSL_PREFIX := $(shell brew --prefix openssl)
OPENSSL := ${OPENSSL_PREFIX}/bin/openssl
else
OPENSSL := $(shell command -v openssl 2> /dev/null)
endif

gitlab_clone_dir = gitlab
gitlab_shell_clone_dir = gitlab-shell
gitlab_workhorse_clone_dir = gitlab-workhorse
gitaly_clone_dir = gitaly
gitlab_pages_clone_dir = gitlab-pages
gitlab_k8s_agent_clone_dir = gitlab-k8s-agent

workhorse_version = $(shell support/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_WORKHORSE_VERSION")
gitlab_shell_version = $(shell support/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_SHELL_VERSION")
gitaly_version = $(shell support/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITALY_SERVER_VERSION")
pages_version = $(shell support/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_PAGES_VERSION")
gitlab_k8s_agent_version = $(shell support/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_KAS_VERSION")
gitlab_elasticsearch_indexer_version = $(shell support/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_ELASTICSEARCH_INDEXER_VERSION")

quiet_bundle_flag = $(shell ${gdk_quiet} && echo "--quiet")
bundle_without_production_cmd = ${BUNDLE} config set without 'production'
bundle_install_cmd = ${BUNDLE} install --jobs 4 ${quiet_bundle_flag}
in_gitlab = cd $(gitlab_development_root)/$(gitlab_clone_dir) &&
gitlab_rake_cmd = $(in_gitlab) ${BUNDLE} exec rake
gitlab_git_cmd = git -C $(gitlab_development_root)/$(gitlab_clone_dir)

psql := $(postgresql_bin_dir)/psql

# Borrowed from https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/Makefile#n87
#
ifeq ($(gdk_debug),true)
	Q =
	QQ =
else
	Q = @
	QQ = > /dev/null
endif

QQerr = 2> /dev/null

ifeq ($(shallow_clone),true)
git_depth_param = --depth=1
endif

# This is used by `gdk install` and `gdk reconfigure`
#
all: preflight-checks \
gitlab-setup \
gitlab-shell-setup \
gitlab-workhorse-setup \
gitlab-pages-setup \
gitlab-k8s-agent-setup \
support-setup \
gitaly-setup \
geo-config \
prom-setup \
object-storage-setup \
gitlab-elasticsearch-indexer-setup

# This is used by `gdk install`
#
install: all show-installed-at start

# This is used by `gdk update`
#
# Pull gitlab directory first since dependencies are linked from there.
update: asdf-update \
ensure-databases-running \
unlock-dependency-installers \
gitlab/.git/pull \
gitlab-shell-update \
gitlab-workhorse-update \
gitlab-pages-update \
gitlab-k8s-agent-update \
gitaly-update \
gitlab-update \
gitlab-elasticsearch-indexer-update \
object-storage-update \
show-updated-at

# This is used by `gdk reconfigure`
#
reconfigure: touch-examples \
unlock-dependency-installers \
postgresql-sensible-defaults \
all \
show-reconfigured-at

self-update: unlock-dependency-installers
	@echo
	@echo "${DIVIDER}"
	@echo "Running self-update on GDK"
	@echo "${DIVIDER}"
	$(Q)git stash ${QQ}
	$(Q)git checkout master ${QQ}
	$(Q)git fetch ${QQ}
	$(Q)support/self-update-git-worktree ${QQ}

clean-config:
	$(Q)rm -rf \
	Procfile \
	gitaly/gitaly-*.praefect.toml \
	gitaly/gitaly.config.toml \
	gitaly/praefect.config.toml \
	gitlab-pages/gitlab-pages.conf \
	gitlab-runner-config.toml \
	gitlab-shell/.gitlab_shell_secret \
	gitlab-shell/config.yml \
	gitlab-workhorse/config.toml \
	gitlab/config/cable.yml \
	gitlab/config/database.yml \
	gitlab/config/database_geo.yml \
	gitlab/config/gitlab.yml \
	gitlab/config/puma.rb \
	gitlab/config/puma_actioncable.rb \
	gitlab/config/resque.yml \
	gitlab/config/unicorn.rb \
	jaeger \
	localhost.crt \
	localhost.key \
	nginx/conf/nginx.conf \
	prometheus/prometheus.yml \
	redis/redis.conf \
	registry/config.yml \
	registry_host.crt \
	registry_host.key

touch-examples:
	$(Q)touch \
	gitlab-shell/config.yml.example \
	gitlab-workhorse/config.toml.example \
	gitlab/config/puma_actioncable.example.development.rb \
	gitlab/config/unicorn.rb.example.development \
	grafana/grafana.ini.example \
	support/templates/**/*.erb \
	support/templates/*.erb

unlock-dependency-installers:
	$(Q)rm -f \
	.gitlab-bundle \
	.gitlab-shell-bundle \
	.gitlab-yarn \
	.gettext \

gdk.yml:
	$(Q)touch $@

.PHONY: Procfile
Procfile:
	$(Q)rake $@

.PHONY: preflight-checks
preflight-checks: rake
	$(Q)rake $@

.PHONY: rake
rake:
	$(Q)command -v $@ ${QQ} || gem install $@

.PHONY: ensure-databases-running
ensure-databases-running: Procfile postgresql/data gitaly-setup
	$(Q)gdk start rails-migration-dependencies

##############################################################
# bootstrap
##############################################################

.PHONY: bootstrap
bootstrap:
	@support/bootstrap

.PHONY: bootstrap-packages
bootstrap-packages:
	@support/bootstrap-packages

##############################################################
# asdf
##############################################################

.PHONY: asdf-update
asdf-update:
ifdef ASDF
	@support/asdf-update
else
	@true
endif

##############################################################
# GitLab
##############################################################

gitlab-setup: gitlab/.git gitlab-config .gitlab-bundle .gitlab-yarn .gettext

gitlab-update: ensure-databases-running postgresql gitlab/.git/pull gitlab-setup gitlab-db-migrate

.PHONY: gitlab/git-restore
gitlab/git-restore:
	$(Q)$(gitlab_git_cmd) ls-tree HEAD --name-only -- Gemfile.lock db/structure.sql db/schema.rb ee/db/geo/schema.rb | xargs $(gitlab_git_cmd) checkout --

gitlab/.git/pull: gitlab/git-restore
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab to current master"
	@echo "${DIVIDER}"
	$(Q)$(gitlab_git_cmd) stash ${QQ}
	$(Q)$(gitlab_git_cmd) checkout master ${QQ}
	$(Q)$(gitlab_git_cmd) pull --ff-only ${QQ}

.PHONY: gitlab-db-migrate
gitlab-db-migrate: ensure-databases-running
	@echo
	$(Q)rake gitlab_rails:db:migrate

gitlab/.git:
	$(Q)git clone ${git_depth_param} ${gitlab_repo} ${gitlab_clone_dir} $(if $(realpath ${gitlab_repo}),--shared)

gitlab-config: gitlab/config/gitlab.yml gitlab/config/database.yml gitlab/config/unicorn.rb gitlab/config/cable.yml gitlab/config/resque.yml gitlab/public/uploads gitlab/config/puma.rb gitlab/config/puma_actioncable.rb

.PHONY: gitlab/config/gitlab.yml
gitlab/config/gitlab.yml:
	$(Q)rake $@

.PHONY: gitlab/config/database.yml
gitlab/config/database.yml:
	$(Q)rake $@

.PHONY: gitlab/config/puma.rb
gitlab/config/puma.rb:
	$(Q)rake $@

# Versions older than GitLab 12.9 won't have this file
gitlab/config/puma_actioncable.example.development.rb:
	$(Q)touch $@

gitlab/config/puma_actioncable.rb: gitlab/config/puma_actioncable.example.development.rb
	$(Q)support/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		"$<"

gitlab/config/unicorn.rb: gitlab/config/unicorn.rb.example.development
	$(Q)support/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		"$<"

.PHONY: gitlab/config/cable.yml
gitlab/config/cable.yml:
	$(Q)rake $@

.PHONY: gitlab/config/resque.yml
gitlab/config/resque.yml:
	$(Q)rake $@

gitlab/public/uploads:
	$(Q)mkdir $@

.gitlab-bundle:
	@echo
	@echo "${DIVIDER}"
	@echo "Installing gitlab-org/gitlab Ruby gems"
	@echo "${DIVIDER}"
	$(Q)$(in_gitlab) gem list bundler -i -v ">=${REQUIRED_BUNDLER_VERSION}" > /dev/null || gem install bundler -v ${REQUIRED_BUNDLER_VERSION}
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

.gettext:
	@echo
	@echo "${DIVIDER}"
	@echo "Generating gitlab-org/gitlab Rails translations"
	@echo "${DIVIDER}"
	$(Q)$(gitlab_rake_cmd) gettext:compile > ${gitlab_development_root}/gitlab/log/gettext.log
	$(Q)$(gitlab_git_cmd) checkout locale/*/gitlab.po
	$(Q)touch $@

##############################################################
# gitlab-shell
##############################################################

gitlab-shell-setup: ${gitlab_shell_clone_dir}/.git gitlab-shell/config.yml .gitlab-shell-bundle gitlab-shell/.gitlab_shell_secret
	$(Q)make -C gitlab-shell build ${QQ}

gitlab-shell-update: gitlab-shell/.git/pull gitlab-shell-setup

gitlab-shell/.git/pull:
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-shell to ${gitlab_shell_version}"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab_shell "${gitlab_development_root}/gitlab-shell" "${gitlab_shell_version}"

# This task is phony to allow
# support/move-existing-gitlab-shell-directory to remove the legacy
# symlink, if necessary. See https://gitlab.com/gitlab-org/gitlab-development-kit/-/merge_requests/1086
.PHONY: ${gitlab_shell_clone_dir}/.git
${gitlab_shell_clone_dir}/.git:
	$(Q)support/move-existing-gitlab-shell-directory || git clone --quiet --branch "${gitlab_shell_version}" ${git_depth_param} ${gitlab_shell_repo} ${gitlab_shell_clone_dir}

.PHONY: gitlab-shell/config.yml
gitlab-shell/config.yml: ${gitlab_shell_clone_dir}/.git
	$(Q)rake $@

.gitlab-shell-bundle:
	$(Q)cd ${gitlab_development_root}/gitlab-shell && $(bundle_install_cmd)
	$(Q)touch $@

gitlab-shell/.gitlab_shell_secret:
	$(Q)ln -s ${gitlab_development_root}/gitlab/.gitlab_shell_secret $@

##############################################################
# gitaly
##############################################################

gitaly-setup: gitaly/bin/gitaly gitaly/gitaly.config.toml gitaly/praefect.config.toml

${gitaly_clone_dir}/.git:
	$(Q)if [ -e gitaly ]; then mv gitaly .backups/$(shell date +gitaly.old.%Y-%m-%d_%H.%M.%S); fi
	$(Q)git clone --quiet ${gitaly_repo} ${gitaly_clone_dir}
	$(Q)support/component-git-update gitaly "${gitaly_clone_dir}" "${gitaly_version}" ${QQ}

gitaly-update: gitaly/.git/pull gitaly-clean gitaly-setup praefect-migrate

.PHONY: gitaly/.git/pull
gitaly/.git/pull: ${gitaly_clone_dir}/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitaly to ${gitaly_version}"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitaly "${gitaly_clone_dir}" "${gitaly_version}" ${QQ}

gitaly-clean:
	$(Q)rm -rf gitlab/tmp/tests/gitaly

.PHONY: gitaly/bin/gitaly
gitaly/bin/gitaly: ${gitaly_clone_dir}/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Building gitlab-org/gitaly ${gitaly_version}"
	@echo "${DIVIDER}"
	$(Q)$(MAKE) -C ${gitaly_clone_dir} BUNDLE_FLAGS=--no-deployment BUILD_TAGS="tracer_static tracer_static_jaeger"
	$(Q)cd ${gitlab_development_root}/gitaly/ruby && $(bundle_install_cmd)

.PHONY: gitaly/gitaly.config.toml
gitaly/gitaly.config.toml:
	$(Q)rake $@

.PHONY: gitaly/praefect.config.toml
gitaly/praefect.config.toml:
	$(Q)rake $@

.PHONY: praefect-migrate
praefect-migrate: postgresql-seed-praefect
	$(Q)support/migrate-praefect

##############################################################
# gitlab-docs
##############################################################

gitlab-docs-setup: gitlab-docs/.git gitlab-docs-bundle gitlab-docs-yarn symlink-gitlab-docs

gitlab-docs/.git:
	$(Q)git clone ${git_depth_param} ${gitlab_docs_repo} gitlab-docs

gitlab-docs/.git/pull:
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-docs to master"
	@echo "${DIVIDER}"
	$(Q)cd ${gitlab_development_root}/gitlab-docs && \
		git stash ${QQ} && \
		git checkout master ${QQ} &&\
		git pull --ff-only ${QQ}

gitlab-docs/nanoc.yaml: gitlab-docs/rm-nanoc.yaml
	$(Q)cp nanoc.yaml.example $@

gitlab-docs-bundle:
	$(Q)cd ${gitlab_development_root}/gitlab-docs && $(bundle_install_cmd)

gitlab-docs-yarn:
	$(Q)cd ${gitlab_development_root}/gitlab-docs && ${YARN} install --frozen-lockfile

symlink-gitlab-docs:
	$(Q)support/symlink ${gitlab_development_root}/gitlab-docs/content/ee ${gitlab_development_root}/gitlab/doc

gitlab-docs-update: gitlab-docs/.git/pull gitlab-docs-bundle gitlab-docs/nanoc.yaml

gitlab-docs-check: gitlab-docs-setup gitlab-docs-update
	$(Q)cd ${gitlab_development_root}/gitlab-docs && \
		bundle exec nanoc && \
		bundle exec nanoc check internal_links && \
		bundle exec nanoc check internal_anchors

##############################################################
# gitlab geo
##############################################################

.PHONY: geo-setup geo-cursor
geo-setup: geo-setup-check Procfile geo-cursor geo-config postgresql/geo

geo-setup-check:
ifneq ($(geo_enabled),true)
	$(Q)echo 'ERROR: geo.enabled is not set to true in your gdk.yml'
	@exit 1
else
	@true
endif

geo-config: gitlab/config/database_geo.yml postgresql/geo/port

geo-cursor:
	$(Q)grep '^geo-cursor:' Procfile || (printf ',s/^#geo-cursor/geo-cursor/\nwq\n' | ed -s Procfile)

.PHONY: gitlab/config/database_geo.yml
gitlab/config/database_geo.yml:
ifeq ($(geo_enabled),true)
	$(Q)rake $@
else
	@true
endif

.PHONY: geo-primary-migrate
geo-primary-migrate: ensure-databases-running .gitlab-bundle gitlab-db-migrate gitlab/git-restore diff-config

.PHONY: geo-primary-update
geo-primary-update: update geo-primary-migrate diff-config

.PHONY: geo-secondary-migrate
geo-secondary-migrate: ensure-databases-running .gitlab-bundle gitlab-db-migrate gitlab/git-restore

.PHONY: geo-secondary-update
geo-secondary-update: update geo-secondary-migrate diff-config

.PHONY: diff-config
diff-config:
	$(Q)gdk $@

##############################################################
# gitlab-workhorse
##############################################################

gitlab-workhorse-setup: gitlab-workhorse/gitlab-workhorse gitlab-workhorse/config.toml

.PHONY: gitlab-workhorse/config.toml
gitlab-workhorse/config.toml:
	$(Q)rake $@

gitlab-workhorse-update: ${gitlab_workhorse_clone_dir}/.git gitlab-workhorse/.git/pull gitlab-workhorse-clean-bin gitlab-workhorse-setup

gitlab-workhorse-clean-bin:
	$(Q)$(MAKE) -C ${gitlab_workhorse_clone_dir} clean

.PHONY: gitlab-workhorse/gitlab-workhorse
gitlab-workhorse/gitlab-workhorse: ${gitlab_workhorse_clone_dir}/.git
	$(Q)$(MAKE) -C ${gitlab_workhorse_clone_dir} ${QQ}

${gitlab_workhorse_clone_dir}/.git:
	$(Q)support/move-existing-workhorse-directory || git clone --quiet --branch "${workhorse_version}" ${git_depth_param} ${gitlab_workhorse_repo} ${gitlab_workhorse_clone_dir}

gitlab-workhorse/.git/pull:
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-workhorse to ${workhorse_version}"
	@echo "${DIVIDER}"
	$(Q)support/remove-empty-file gitlab-workhorse/config.toml.example
	$(Q)support/component-git-update workhorse "${gitlab_workhorse_clone_dir}" "${workhorse_version}"

##############################################################
# gitlab-elasticsearch
##############################################################

gitlab-elasticsearch-indexer-setup: gitlab-elasticsearch-indexer/bin/gitlab-elasticsearch-indexer

gitlab-elasticsearch-indexer-update: gitlab-elasticsearch-indexer/.git/pull gitlab-elasticsearch-indexer-clean-bin gitlab-elasticsearch-indexer/bin/gitlab-elasticsearch-indexer

gitlab-elasticsearch-indexer-clean-bin:
	$(Q)rm -rf gitlab-elasticsearch-indexer/bin

gitlab-elasticsearch-indexer/.git:
	$(Q)git clone --quiet --branch "${gitlab_elasticsearch_indexer_version}" ${git_depth_param} ${gitlab_elasticsearch_indexer_repo} gitlab-elasticsearch-indexer

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

##############################################################
# gitlab-pages
##############################################################

gitlab-pages-setup: gitlab-pages-secret gitlab-pages/gitlab-pages.conf gitlab-pages/bin/gitlab-pages

gitlab-pages-secret:
	$(Q)rake $@

.PHONY: gitlab-pages/gitlab-pages.conf
gitlab-pages/gitlab-pages.conf: ${gitlab_pages_clone_dir}/.git
	$(Q)rake $@

gitlab-pages-update: ${gitlab_pages_clone_dir}/.git gitlab-pages/.git/pull gitlab-pages-clean-bin gitlab-pages/bin/gitlab-pages gitlab-pages/gitlab-pages.conf

gitlab-pages-clean-bin:
	$(Q)rm -f gitlab-pages/bin/gitlab-pages

.PHONY: gitlab-pages/bin/gitlab-pages
gitlab-pages/bin/gitlab-pages: ${gitlab_pages_clone_dir}/.git
	$(Q)$(MAKE) -C ${gitlab_pages_clone_dir} ${QQ}

${gitlab_pages_clone_dir}/.git:
	$(Q)support/move-existing-gitlab-pages-directory || git clone --quiet --branch "${pages_version}" ${git_depth_param} ${gitlab_pages_repo} ${gitlab_pages_clone_dir} ${QQ}

gitlab-pages/.git/pull:
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-pages to ${pages_version}"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab_pages "${gitlab_pages_clone_dir}" "${pages_version}"

##############################################################
# gitlab Kubernetes agent
##############################################################

ifeq ($(gitlab_k8s_agent_enabled),true)
gitlab-k8s-agent-setup: gitlab-k8s-agent/build/gdk/bin/kas_race gitlab-k8s-agent-config.yml
else
gitlab-k8s-agent-setup:
	@true
endif

ifeq ($(gitlab_k8s_agent_enabled),true)
gitlab-k8s-agent-update: ${gitlab_k8s_agent_clone_dir}/.git gitlab-k8s-agent/.git/pull gitlab-k8s-agent/build/gdk/bin/kas_race
else
gitlab-k8s-agent-update:
	@true
endif

.PHONY: gitlab-k8s-agent-config.yml
gitlab-k8s-agent-config.yml:
	$(Q)rake $@

.PHONY: gitlab-k8s-agent-clean
gitlab-k8s-agent-clean:
	$(Q)rm -rf "${gitlab_k8s_agent_clone_dir}/build/gdk/bin"
	cd "${gitlab_k8s_agent_clone_dir}" && bazel clean

gitlab-k8s-agent/build/gdk/bin/kas_race: ${gitlab_k8s_agent_clone_dir}/.git gitlab-k8s-agent/bazel
	@echo
	@echo "${DIVIDER}"
	@echo "Installing gitlab-org/cluster-integration/gitlab-agent"
	@echo "${DIVIDER}"
	$(Q)mkdir -p "${gitlab_k8s_agent_clone_dir}/build/gdk/bin"
	$(Q)$(MAKE) -C "${gitlab_k8s_agent_clone_dir}" gdk-install TARGET_DIRECTORY="$(CURDIR)/${gitlab_k8s_agent_clone_dir}/build/gdk/bin" ${QQ}

ifeq ($(platform),macos)
gitlab-k8s-agent/bazel: /usr/local/bin/bazelisk
	$(Q)touch $@
else
.PHONY: gitlab-k8s-agent/bazel
gitlab-k8s-agent/bazel:
	@echo "INFO: To install bazel, please consult the docs at https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/master/doc/howto/kubernetes_agent.md"
endif

/usr/local/bin/bazelisk:
	$(Q)brew install bazelisk

${gitlab_k8s_agent_clone_dir}/.git:
	$(Q)git clone --quiet --branch "${gitlab_k8s_agent_version}" ${git_depth_param} ${gitlab_k8s_agent_repo} ${gitlab_k8s_agent_clone_dir} ${QQ}

gitlab-k8s-agent/.git/pull:
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/cluster-integration/gitlab-agent to ${gitlab_k8s_agent_version}"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab_k8s_agent "${gitlab_k8s_agent_clone_dir}" "${gitlab_k8s_agent_version}"

##############################################################
# gitlab performance metrics
##############################################################

performance-metrics-setup: Procfile grafana-setup

##############################################################
# gitlab support setup
##############################################################

support-setup: Procfile redis gitaly-setup jaeger-setup postgresql openssh-setup nginx-setup registry-setup elasticsearch-setup runner-setup
ifeq ($(auto_devops_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Tunnel URLs"
	@echo
	@echo "GitLab: https://${hostname}"
	@echo "Registry: https://${registry_host}"
	@echo "${DIVIDER}"
endif

##############################################################
# redis
##############################################################

redis: redis/redis.conf

.PHONY: redis/redis.conf
redis/redis.conf:
	$(Q)rake $@

##############################################################
# postgresql
##############################################################

postgresql: postgresql/data postgresql/port postgresql-seed-rails postgresql-seed-praefect

postgresql/data:
	$(Q)${postgresql_bin_dir}/initdb --locale=C -E utf-8 ${postgresql_data_dir}

.PHONY: postgresql-seed-rails
postgresql-seed-rails: ensure-databases-running postgresql-seed-praefect
	$(Q)support/bootstrap-rails

.PHONY: postgresql-seed-praefect
postgresql-seed-praefect: Procfile postgresql/data
	$(Q)gdk start db
	$(Q)support/bootstrap-praefect

postgresql/port:
	$(Q)support/postgres-port ${postgresql_dir} ${postgresql_port}

postgresql-sensible-defaults:
	$(Q)support/postgresql-sensible-defaults ${postgresql_dir}

##############################################################
# postgresql replication
##############################################################

postgresql-replication-primary: postgresql-replication/access postgresql-replication/role postgresql-replication/config

postgresql-replication-secondary: postgresql-replication/data postgresql-replication/access postgresql-replication/backup postgresql-replication/config

postgresql-replication-primary-create-slot: postgresql-replication/slot

postgresql-replication/data:
	${postgresql_bin_dir}/initdb --locale=C -E utf-8 ${postgresql_data_dir}

postgresql-replication/access:
	$(Q)cat support/pg_hba.conf.add >> ${postgresql_data_dir}/pg_hba.conf

postgresql-replication/role:
	$(Q)$(psql) -h ${postgresql_host} -p ${postgresql_port} -d postgres -c "CREATE ROLE ${postgresql_replication_user} WITH REPLICATION LOGIN;"

postgresql-replication/backup:
	$(Q)$(eval postgresql_primary_dir := $(realpath postgresql-primary))
	$(Q)$(eval postgresql_primary_host := $(shell cd ${postgresql_primary_dir}/../ && gdk config get postgresql.host $(QQerr)))
	$(Q)$(eval postgresql_primary_port := $(shell cd ${postgresql_primary_dir}/../ && gdk config get postgresql.port $(QQerr)))

	$(Q)$(psql) -h ${postgresql_primary_host} -p ${postgresql_primary_port} -d postgres -c "select pg_start_backup('base backup for streaming rep')"
	$(Q)rsync -cva --inplace --exclude="*pg_xlog*" --exclude="*.pid" ${postgresql_primary_dir}/data postgresql
	$(Q)$(psql) -h ${postgresql_primary_host} -p ${postgresql_primary_port} -d postgres -c "select pg_stop_backup(), current_timestamp"
	$(Q)./support/recovery.conf ${postgresql_primary_host} ${postgresql_primary_port} > ${postgresql_data_dir}/recovery.conf
	$(Q)$(MAKE) postgresql/port ${QQ}

postgresql-replication/slot:
	$(Q)$(psql) -h ${postgresql_host} -p ${postgresql_port} -d postgres -c "SELECT * FROM pg_create_physical_replication_slot('gitlab_gdk_replication_slot');"

postgresql-replication/list-slots:
	$(Q)$(psql) -h ${postgresql_host} -p ${postgresql_port} -d postgres -c "SELECT * FROM pg_replication_slots;"

postgresql-replication/drop-slot:
	$(Q)$(psql) -h ${postgresql_host} -p ${postgresql_port} -d postgres -c "SELECT * FROM pg_drop_replication_slot('gitlab_gdk_replication_slot');"

postgresql-replication/config:
	$(Q)./support/postgres-replication ${postgresql_dir}

##############################################################
# postgresql geo
##############################################################

postgresql/geo: postgresql-geo/data postgresql/geo/port postgresql/geo/seed-data

postgresql-geo/data:
ifeq ($(geo_enabled),true)
	$(Q)${postgresql_bin_dir}/initdb --locale=C -E utf-8 postgresql-geo/data
else
	@true
endif

postgresql/geo/port: postgresql-geo/data
ifeq ($(geo_enabled),true)
	$(Q)support/postgres-port ${postgresql_geo_dir} ${postgresql_geo_port}
else
	@true
endif

postgresql/geo/Procfile:
	$(Q)grep '^postgresql-geo:' Procfile || (printf ',s/^#postgresql-geo/postgresql-geo/\nwq\n' | ed -s Procfile)

postgresql/geo/seed-data:
	$(Q)support/bootstrap-geo

##############################################################
# influxdb
##############################################################

influxdb-setup:
	$(Q)echo "INFO: InfluxDB was removed from the GDK by https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues/927"

##############################################################
# elasticsearch
##############################################################

elasticsearch-setup: elasticsearch/bin/elasticsearch

elasticsearch/bin/elasticsearch: elasticsearch-${elasticsearch_version}.tar.gz
	$(Q)rm -rf elasticsearch
	$(Q)tar zxf elasticsearch-${elasticsearch_version}.tar.gz
	$(Q)mv elasticsearch-${elasticsearch_version} elasticsearch
	$(Q)touch $@

elasticsearch-${elasticsearch_version}.tar.gz:
	$(Q)./support/download-elasticsearch "${elasticsearch_version}" "$@" "${elasticsearch_mac_tar_gz_sha512}" "${elasticsearch_linux_tar_gz_sha512}"

##############################################################
# minio / object storage
##############################################################

object-storage-update: object-storage-setup

object-storage-setup: minio/data/lfs-objects minio/data/artifacts minio/data/uploads minio/data/packages minio/data/terraform minio/data/pages minio/data/external-diffs

minio/data/%:
	$(Q)mkdir -p $@

##############################################################
# prometheus
##############################################################

prom-setup: prometheus/prometheus.yml

.PHONY: prometheus/prometheus.yml
prometheus/prometheus.yml:
	$(Q)rake $@

##############################################################
# grafana
##############################################################

grafana-setup: grafana/grafana.ini grafana/bin/grafana-server grafana/gdk-pg-created grafana/gdk-data-source-created

grafana/bin/grafana-server:
	$(Q)cd grafana && ${MAKE} ${QQ}

grafana/grafana.ini: grafana/grafana.ini.example
	$(Q)support/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		-e "s/GDK_USERNAME/${username}/g" \
		"$<"

grafana/gdk-pg-created:
	$(Q)support/create-grafana-db
	$(Q)touch $@

grafana/gdk-data-source-created:
	$(Q)grep '^grafana:' Procfile || (printf ',s/^#grafana/grafana/\nwq\n' | ed -s Procfile)
	$(Q)touch $@

##############################################################
# openssh
##############################################################

openssh-setup: openssh/sshd_config openssh/ssh_host_rsa_key

openssh/ssh_host_rsa_key:
	$(Q)ssh-keygen -f $@ -N '' -t rsa

nginx-setup: nginx/conf/nginx.conf nginx/logs nginx/tmp

.PHONY: nginx/conf/nginx.conf
nginx/conf/nginx.conf:
	$(Q)rake $@

.PHONY: openssh/sshd_config
openssh/sshd_config:
	$(Q)rake $@

##############################################################
# nginx
##############################################################

nginx/logs:
	$(Q)mkdir -p $@

nginx/tmp:
	$(Q)mkdir -p $@

##############################################################
# registry
##############################################################

registry-setup: registry/storage registry/config.yml localhost.crt

localhost.crt: localhost.key

localhost.key:
	$(Q)${OPENSSL} req -new -subj "/CN=${registry_host}/" -x509 -days 365 -newkey rsa:2048 -nodes -keyout "localhost.key" -out "localhost.crt"
	$(Q)chmod 600 $@

registry_host.crt: registry_host.key

registry_host.key:
	$(Q)${OPENSSL} req -new -subj "/CN=${registry_host}/" -x509 -days 365 -newkey rsa:2048 -nodes -keyout "registry_host.key" -out "registry_host.crt" -addext "subjectAltName=DNS:${registry_host}"
	$(Q)chmod 600 $@

registry/storage:
	$(Q)mkdir -p $@

.PHONY: registry/config.yml
registry/config.yml: registry_host.crt
	$(Q)rake $@

.PHONY: trust-docker-registry
trust-docker-registry: registry_host.crt
	$(Q)mkdir -p "${HOME}/.docker/certs.d/${registry_host}:${registry_port}"
	$(Q)rm -f "${HOME}/.docker/certs.d/${registry_host}:${registry_port}/ca.crt"
	$(Q)cp registry_host.crt "${HOME}/.docker/certs.d/${registry_host}:${registry_port}/ca.crt"
	$(Q)echo "Certificates have been copied to ~/.docker/certs.d/"
	$(Q)echo "Don't forget to restart Docker!"

##############################################################
# runner
##############################################################

runner-setup: gitlab-runner-config.toml

.PHONY: gitlab-runner-config.toml
ifeq ($(runner_enabled),true)
gitlab-runner-config.toml:
	$(Q)rake $@
else
gitlab-runner-config.toml:
	@true
endif

##############################################################
# jaeger
##############################################################

ifeq ($(jaeger_server_enabled),true)
.PHONY: jaeger-setup
jaeger-setup: jaeger/jaeger-${jaeger_version}/jaeger-all-in-one
else
.PHONY: jaeger-setup
jaeger-setup:
	@true
endif

jaeger-artifacts/jaeger-${jaeger_version}.tar.gz:
	$(Q)mkdir -p $(@D)
	$(Q)./support/download-jaeger "${jaeger_version}" "$@"
	# To save disk space, delete old versions of the download,
	# but to save bandwidth keep the current version....
	$(Q)find jaeger-artifacts ! -path "$@" -type f -exec rm -f {} + -print

jaeger/jaeger-${jaeger_version}/jaeger-all-in-one: jaeger-artifacts/jaeger-${jaeger_version}.tar.gz
	@echo
	@echo "${DIVIDER}"
	@echo "Installing jaeger ${jaeger_version}"
	@echo "${DIVIDER}"

	$(Q)mkdir -p "jaeger/jaeger-${jaeger_version}"
	$(Q)tar -xf "$<" -C "jaeger/jaeger-${jaeger_version}" --strip-components 1

##############################################################
# Tests
##############################################################

.PHONY: test
test: lint shellcheck rubocop rspec gdk_example_yml

.PHONY: rubocop
rubocop:
ifeq ($(and $(BUNDLE)),)
	@echo "ERROR: Bundler is not installed, please ensure you've bootstrapped your machine. See https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/index.md for more details"
	@false
else
ifeq ($(and $(RUBOCOP)),)
	@echo "INFO: Installing RuboCop.."
	$(Q)${bundle_install_cmd} ${QQ}
endif
	@echo -n "RuboCop: "
	@${BUNDLE} exec $@ --config .rubocop-gdk.yml --parallel
endif

.PHONY: rspec
rspec:
ifeq ($(and $(BUNDLE)),)
	@echo "ERROR: Bundler is not installed, please ensure you've bootstrapped your machine. See https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/index.md for more details"
	@false
else
ifeq ($(and $(RSPEC)),)
	@echo "INFO: Installing RSpec.."
	$(Q)${bundle_install_cmd} ${QQ}
endif
	@echo -n "RSpec: "
	@${BUNDLE} exec $@
endif

.PHONY: lint
lint: vale markdownlint

.PHONY: vale-install
vale-install:
ifeq ($(and $(GOLANG)),)
	@echo "ERROR: Golang is not installed, please ensure you've bootstrapped your machine. See https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/index.md for more details"
	@false
else
ifeq ($(and $(VALE)),)
	@echo "INFO: Installing vale.."
	@GO111MODULE=on ${GOLANG} get github.com/errata-ai/vale/v2 ${QQ}
endif
endif

.PHONY: vale
vale: vale-install
	@echo -n "Vale: "
	$(eval VALE := $(shell command -v vale 2> /dev/null))
	@${VALE} --minAlertLevel error *.md doc

.PHONY: markdownlint-install
markdownlint-install:
ifeq ($(or $(NPM),$(YARN)),)
	@echo "ERROR: NPM or YARN are not installed, please ensure you've bootstrapped your machine. See https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/index.md for more details"
	@false
else
ifeq ($(and $(MARKDOWNLINT)),)
	@echo "INFO: Installing markdownlint.."
	@([[ "${YARN}" ]] && ${YARN} global add markdownlint-cli@0.23.2 ${QQ}) || ([[ "${NPM}" ]] && ${NPM} install -g markdownlint-cli@0.23.2 ${QQ})
endif
	@([[ "${ASDF}" ]] && ${ASDF} reshim nodejs || true)
endif

.PHONY: markdownlint
markdownlint: markdownlint-install
	$(eval MARKDOWNLINT := $(shell command -v markdownlint 2> /dev/null))
	@echo -n "MarkdownLint: "
	@${MARKDOWNLINT} --config .markdownlint.json 'doc/**/*.md' && echo "OK"

.PHONY: shellcheck-install
shellcheck-install:
ifeq ($(and $(SHELLCHECK)),)
ifeq ($(platform),macos)
	@echo "INFO: Installing Shellcheck.."
	$(Q)brew install shellcheck ${QQ}
else
	@echo "INFO: To install shellcheck, please consult the docs at https://github.com/koalaman/shellcheck#installing"
	@false
endif
endif

.PHONY: shellcheck
shellcheck: shellcheck-install
	@echo -n "Shellcheck: "
	@support/shellcheck && echo "OK"

.PHONY: gdk_example_yml
gdk_example_yml:
	@echo -n "Checking gdk.example.yml: "
	@support/ci/gdk_example_yml && echo "OK"

##############################################################
# Misc
##############################################################

.PHONY: start
start:
	@echo
	$(Q)gdk start

.PHONY: ask-to-restart
ask-to-restart:
	@echo
	$(Q)support/ask-to-restart
	@echo

.PHONY: show-installed-at
show-installed-at:
	@echo
	@echo "> Installed as of $$(date +"%Y-%m-%d %T")"

.PHONY: show-updated-at
show-updated-at:
	@echo
	@echo "> Updated as of $$(date +"%Y-%m-%d %T")"

.PHONY: show-reconfigured-at
show-reconfigured-at:
	@echo
	@echo "> Reconfigured as of $$(date +"%Y-%m-%d %T")"
