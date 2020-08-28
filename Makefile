.NOTPARALLEL:

SHELL = /bin/bash
RAKE := $(shell command -v rake 2> /dev/null)

# Speed up Go module downloads
export GOPROXY ?= https://proxy.golang.org

# Generate a Makefile from Ruby and include it
ifdef RAKE
ifneq ($(MAKECMDGOALS),bootstrap)
include $(shell rake gdk-config.mk)
endif
endif

gitlab_clone_dir = gitlab
gitlab_shell_clone_dir = gitlab-shell
gitlab_workhorse_clone_dir = gitlab-workhorse
gitaly_clone_dir = gitaly
gitlab_pages_clone_dir = gitlab-pages
gitlab_k8s_agent_clone_dir = gitlab-k8s-agent

workhorse_version = $(shell bin/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_WORKHORSE_VERSION")
gitlab_shell_version = $(shell bin/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_SHELL_VERSION")
gitaly_version = $(shell bin/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITALY_SERVER_VERSION")
pages_version = $(shell bin/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_PAGES_VERSION")
gitlab_k8s_agent_version = "master"
gitlab_elasticsearch_indexer_version = $(shell bin/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_ELASTICSEARCH_INDEXER_VERSION")

quiet_bundle_flag = $(shell ${gdk_quiet} && echo " | egrep -v '^Using '")
bundle_install_cmd = bundle install --jobs 4 --without production ${quiet_bundle_flag}
in_gitlab = cd $(gitlab_development_root)/$(gitlab_clone_dir) &&
gitlab_rake_cmd = $(in_gitlab) bundle exec rake
gitlab_git_cmd = git -C $(gitlab_development_root)/$(gitlab_clone_dir)

psql := $(postgresql_bin_dir)/psql

postgresql_in_recovery_cmd = $(psql) -X -h $(postgresql_host) -p $(postgresql_port) -d postgres -tc 'SELECT pg_is_in_recovery();' $(QQerr)
when_postgresql_not_in_recovery = [[ "$$($(postgresql_in_recovery_cmd) | tr -d '[:space:]')" == "t" ]] ||

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
install: all show-installed-at

# This is used by `gdk update`
#
# Pull gitlab directory first since dependencies are linked from there.
update: ensure-databases-running \
unlock-dependency-installers \
gitlab/.git/pull \
gitlab-shell-update \
gitlab-workhorse-update \
gitlab-pages-update \
gitlab-k8s-agent-update \
gitaly-update \
gitlab-update \
gitlab-elasticsearch-indexer-update \
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
	@echo "------------------------------------------------------------"
	@echo "Running self-update on GDK"
	@echo "------------------------------------------------------------"
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
	gitlab/config/puma.example.development.rb \
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

bootstrap: install-prerequisites

install-prerequisites:
	${Q}support/bootstrap/install_prerequisites

##############################################################
# GitLab
##############################################################

gitlab-setup: gitlab/.git gitlab-config .gitlab-bundle .gitlab-yarn .gettext

gitlab-update: ensure-databases-running postgresql gitlab/.git/pull gitlab-setup gitlab-db-migrate gitlab-geo-db-migrate

.PHONY: gitlab/git-restore
gitlab/git-restore:
	$(Q)$(gitlab_git_cmd) ls-tree HEAD --name-only -- Gemfile.lock db/structure.sql db/schema.rb ee/db/geo/schema.rb | xargs $(gitlab_git_cmd) checkout --

gitlab/.git/pull: gitlab/git-restore
	@echo
	@echo "------------------------------------------------------------"
	@echo "Updating gitlab-org/gitlab to current master"
	@echo "------------------------------------------------------------"
	$(Q)$(gitlab_git_cmd) stash ${QQ}
	$(Q)$(gitlab_git_cmd) checkout master ${QQ}
	$(Q)$(gitlab_git_cmd) pull --ff-only ${QQ}

gitlab-db-migrate:
	@$(when_postgresql_not_in_recovery)echo "------------------------------------------------------------"
	@$(when_postgresql_not_in_recovery)echo "Processing gitlab-org/gitlab Rails DB migrations"
	@$(when_postgresql_not_in_recovery)echo "------------------------------------------------------------"
	$(Q)$(when_postgresql_not_in_recovery)($(gitlab_rake_cmd) db:migrate db:test:prepare)

gitlab-geo-db-migrate:
ifeq ($(geo_enabled),true)
	@echo
	@echo "------------------------------------------------------------"
	@echo "Processing gitlab-org/gitlab Rails Geo DB migrations"
	@echo "------------------------------------------------------------"
	$(Q)$(gitlab_rake_cmd) geo:db:migrate geo:db:test:prepare
else
	@true
endif

gitlab/.git:
	$(Q)git clone ${git_depth_param} ${gitlab_repo} ${gitlab_clone_dir} $(if $(realpath ${gitlab_repo}),--shared)

gitlab-config: gitlab/config/gitlab.yml gitlab/config/database.yml gitlab/config/unicorn.rb gitlab/config/cable.yml gitlab/config/resque.yml gitlab/public/uploads gitlab/config/puma.rb gitlab/config/puma_actioncable.rb gitlab/.root_password

.PHONY: gitlab/config/gitlab.yml
gitlab/config/gitlab.yml:
	$(Q)rake $@

.PHONY: gitlab/config/database.yml
gitlab/config/database.yml:
	$(Q)rake $@

gitlab/.root_password:
	openssl rand -base64 10 > $@

# Versions older than GitLab 11.5 won't have this file
gitlab/config/puma.example.development.rb:
	$(Q)touch $@

gitlab/config/puma.rb: gitlab/config/puma.example.development.rb
	$(Q)bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		"$<"

# Versions older than GitLab 12.9 won't have this file
gitlab/config/puma_actioncable.example.development.rb:
	$(Q)touch $@

gitlab/config/puma_actioncable.rb: gitlab/config/puma_actioncable.example.development.rb
	$(Q)bin/safe-sed "$@" \
		-e "s|/home/git|${gitlab_development_root}|g" \
		"$<"

gitlab/config/unicorn.rb: gitlab/config/unicorn.rb.example.development
	$(Q)bin/safe-sed "$@" \
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
	@echo "------------------------------------------------------------"
	@echo "Installing gitlab-org/gitlab Ruby gems"
	@echo "------------------------------------------------------------"
	$(Q)$(in_gitlab) $(bundle_install_cmd)
	$(Q)touch $@

.gitlab-yarn:
	@echo
	@echo "------------------------------------------------------------"
	@echo "Installing gitlab-org/gitlab Node.js packages"
	@echo "------------------------------------------------------------"
	$(Q)$(in_gitlab) yarn install --pure-lockfile ${QQ}
	$(Q)touch $@

.gettext:
	@echo
	@echo "------------------------------------------------------------"
	@echo "Generating gitlab-org/gitlab Rails translations"
	@echo "------------------------------------------------------------"
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
	@echo "------------------------------------------------------------"
	@echo "Updating gitlab-org/gitlab-shell to ${gitlab_shell_version}"
	@echo "------------------------------------------------------------"
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
	@echo "------------------------------------------------------------"
	@echo "Updating gitlab-org/gitaly to ${gitaly_version}"
	@echo "------------------------------------------------------------"
	$(Q)support/component-git-update gitaly "${gitaly_clone_dir}" "${gitaly_version}" ${QQ}

gitaly-clean:
	$(Q)rm -rf gitlab/tmp/tests/gitaly

.PHONY: gitaly/bin/gitaly
gitaly/bin/gitaly: ${gitaly_clone_dir}/.git
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

gitlab-docs-setup: gitlab-docs/.git gitlab-docs-bundle gitlab-docs/nanoc.yaml symlink-gitlab-docs

gitlab-docs/.git:
	$(Q)git clone ${git_depth_param} ${gitlab_docs_repo} gitlab-docs

gitlab-docs/.git/pull:
	@echo
	@echo "------------------------------------------------------------"
	@echo "Updating gitlab-org/gitlab-docs to master"
	@echo "------------------------------------------------------------"
	$(Q)cd gitlab-docs && \
		git stash ${QQ} && \
		git checkout master ${QQ} &&\
		git pull --ff-only ${QQ}

# We need to force delete since there's already a nanoc.yaml file
# in the docs folder which we need to overwrite.
gitlab-docs/rm-nanoc.yaml:
	$(Q)rm -f gitlab-docs/nanoc.yaml

gitlab-docs/nanoc.yaml: gitlab-docs/rm-nanoc.yaml
	$(Q)cp nanoc.yaml.example $@

gitlab-docs-bundle:
	$(Q)cd ${gitlab_development_root}/gitlab-docs && $(bundle_install_cmd)

symlink-gitlab-docs:
	$(Q)support/symlink ${gitlab_development_root}/gitlab-docs/content/ee ${gitlab_development_root}/gitlab/doc

gitlab-docs-update: gitlab-docs/.git/pull gitlab-docs-bundle gitlab-docs/nanoc.yaml

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
geo-primary-migrate: ensure-databases-running .gitlab-bundle gitlab-db-migrate gitlab-geo-db-migrate gitlab/git-restore diff-config

.PHONY: geo-primary-update
geo-primary-update: update geo-primary-migrate diff-config

.PHONY: geo-secondary-migrate
geo-secondary-migrate: ensure-databases-running .gitlab-bundle gitlab-geo-db-migrate gitlab/git-restore

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
	@echo "------------------------------------------------------------"
	@echo "Updating gitlab-org/gitlab-workhorse to ${workhorse_version}"
	@echo "------------------------------------------------------------"
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
	@echo "------------------------------------------------------------"
	@echo "Updating gitlab-org/gitlab-elasticsearch-indexer to ${gitlab_elasticsearch_indexer_version}"
	@echo "------------------------------------------------------------"
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
	@echo "------------------------------------------------------------"
	@echo "Updating gitlab-org/gitlab-pages to ${pages_version}"
	@echo "------------------------------------------------------------"
	$(Q)support/component-git-update gitlab_pages "${gitlab_pages_clone_dir}" "${pages_version}"

##############################################################
# gitlab Kubernetes agent
##############################################################

ifeq ($(gitlab_k8s_agent_enabled),true)
gitlab-k8s-agent-setup: gitlab-k8s-agent/build/gdk/bin/kas_race
else
gitlab-k8s-agent-setup:
	@true
endif

ifeq ($(gitlab_k8s_agent_enabled),true)
gitlab-k8s-agent-update: ${gitlab_k8s_agent_clone_dir}/.git gitlab-k8s-agent/.git/pull gitlab-k8s-agent-clean-bin gitlab-k8s-agent/build/gdk/bin/kas_race
else
gitlab-k8s-agent-update:
	@true
endif

gitlab-k8s-agent-clean-bin:
	$(Q)rm -rf "${gitlab_k8s_agent_clone_dir}/build/gdk/bin"

gitlab-k8s-agent/build/gdk/bin/kas_race: ${gitlab_k8s_agent_clone_dir}/.git gitlab-k8s-agent/bazel
	@echo
	@echo "------------------------------------------------------------"
	@echo "Installing gitlab-org/cluster-integration/gitlab-agent"
	@echo "------------------------------------------------------------"
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
	@echo "------------------------------------------------------------"
	@echo "Updating gitlab-org/cluster-integration/gitlab-agent to ${gitlab_k8s_agent_version}"
	@echo "------------------------------------------------------------"
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
	@echo "------------------------------------------------------------"
	@echo "Tunnel URLs"
	@echo
	@echo "GitLab: https://${hostname}"
	@echo "Registry: https://${registry_host}"
	@echo "------------------------------------------------------------"
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
	$(Q)gdk start postgresql
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
	$(Q)./bin/download-elasticsearch "${elasticsearch_version}" "$@" "${elasticsearch_mac_tar_gz_sha512}" "${elasticsearch_linux_tar_gz_sha512}"

##############################################################
# minio / object storage
##############################################################

object-storage-setup: minio/data/lfs-objects minio/data/artifacts minio/data/uploads minio/data/packages

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
	$(Q)bin/safe-sed "$@" \
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
	$(Q)openssl req -new -subj "/CN=${registry_host}/" -x509 -days 365 -newkey rsa:2048 -nodes -keyout "localhost.key" -out "localhost.crt"
	$(Q)chmod 600 $@

registry_host.crt: registry_host.key

registry_host.key:
	$(Q)openssl req -new -subj "/CN=${registry_host}/" -x509 -days 365 -newkey rsa:2048 -nodes -keyout "registry_host.key" -out "registry_host.crt"
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
	$(Q)./bin/download-jaeger "${jaeger_version}" "$@"
	# To save disk space, delete old versions of the download,
	# but to save bandwidth keep the current version....
	$(Q)find jaeger-artifacts ! -path "$@" -type f -exec rm -f {} + -print

jaeger/jaeger-${jaeger_version}/jaeger-all-in-one: jaeger-artifacts/jaeger-${jaeger_version}.tar.gz
	@echo
	@echo "------------------------------------------------------------"
	@echo "Installing jaeger ${jaeger_version}"
	@echo "------------------------------------------------------------"

	$(Q)mkdir -p "jaeger/jaeger-${jaeger_version}"
	$(Q)tar -xf "$<" -C "jaeger/jaeger-${jaeger_version}" --strip-components 1

##############################################################
# Tests
##############################################################

.PHONY: test
test: lint rubocop rspec

.PHONY: rubocop
rubocop:
	$(Q)bundle exec rubocop --config .rubocop-gdk.yml --parallel

.PHONY: rspec
rspec:
	$(Q)bundle exec $@

.PHONY: lint
lint: lint-vale lint-markdown

.PHONY: install-vale
install-vale:
	$(Q)(command -v vale > /dev/null) || go get github.com/errata-ai/vale

.PHONY: lint-vale
lint-vale: install-vale
	$(Q)vale --minAlertLevel error *.md doc

.PHONY: install-markdownlint
install-markdownlint:
	$(Q)(command -v markdownlint > /dev/null) || \
	((command -v npm > /dev/null) && npm install -g markdownlint-cli) || \
	((command -v yarn > /dev/null) && yarn global add markdownlint-cli)

.PHONY: lint-markdown
lint-markdown: install-markdownlint
	$(Q)markdownlint --config .markdownlint.json 'doc/**/*.md'

##############################################################
# Misc
##############################################################

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
