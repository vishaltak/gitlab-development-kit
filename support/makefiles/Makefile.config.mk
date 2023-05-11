# ---------------------------------------------------------------------------------------------
# This file is used by the GDK to get interoperability between Make and Rake with the end
# goal of getting rid of Make in the future: https://gitlab.com/groups/gitlab-org/-/epics/1556.
# This file can be generated with the `rake support/makefiles/Makefile.config.mk` task.
# ---------------------------------------------------------------------------------------------

.PHONY: Procfile
Procfile:
	$(Q)rake Procfile

.PHONY: gitlab/config/cable.yml
gitlab/config/cable.yml:
	$(Q)rake gitlab/config/cable.yml

.PHONY: gitlab/config/database.yml
gitlab/config/database.yml:
	$(Q)rake gitlab/config/database.yml

.PHONY: gitlab/config/gitlab.yml
gitlab/config/gitlab.yml:
	$(Q)rake gitlab/config/gitlab.yml

.PHONY: gitlab/config/puma.rb
gitlab/config/puma.rb:
	$(Q)rake gitlab/config/puma.rb

.PHONY: gitlab/config/redis.cache.yml
gitlab/config/redis.cache.yml:
	$(Q)rake gitlab/config/redis.cache.yml

.PHONY: gitlab/config/redis.repository_cache.yml
gitlab/config/redis.repository_cache.yml:
	$(Q)rake gitlab/config/redis.repository_cache.yml

.PHONY: gitlab/config/redis.queues.yml
gitlab/config/redis.queues.yml:
	$(Q)rake gitlab/config/redis.queues.yml

.PHONY: gitlab/config/redis.rate_limiting.yml
gitlab/config/redis.rate_limiting.yml:
	$(Q)rake gitlab/config/redis.rate_limiting.yml

.PHONY: gitlab/config/redis.sessions.yml
gitlab/config/redis.sessions.yml:
	$(Q)rake gitlab/config/redis.sessions.yml

.PHONY: gitlab/config/redis.shared_state.yml
gitlab/config/redis.shared_state.yml:
	$(Q)rake gitlab/config/redis.shared_state.yml

.PHONY: gitlab/config/redis.trace_chunks.yml
gitlab/config/redis.trace_chunks.yml:
	$(Q)rake gitlab/config/redis.trace_chunks.yml

.PHONY: gitlab/config/resque.yml
gitlab/config/resque.yml:
	$(Q)rake gitlab/config/resque.yml

.PHONY: gitlab/workhorse/config.toml
gitlab/workhorse/config.toml:
	$(Q)rake gitlab/workhorse/config.toml

.PHONY: gitlab-k8s-agent-config.yml
gitlab-k8s-agent-config.yml:
	$(Q)rake gitlab-k8s-agent-config.yml

.PHONY: gitlab-pages/gitlab-pages.conf
gitlab-pages/gitlab-pages.conf: gitlab-pages/.git/pull
	$(Q)rake gitlab-pages/gitlab-pages.conf

.PHONY: gitlab-pages-secret
gitlab-pages-secret:
	$(Q)rake gitlab-pages-secret

.PHONY: gitlab-runner-config.toml
gitlab-runner-config.toml:
ifeq ($(runner_enabled),true)
	$(Q)rake gitlab-runner-config.toml
else
	@true
endif

.PHONY: gitlab-shell/config.yml
gitlab-shell/config.yml: gitlab-shell/.git
	$(Q)rake gitlab-shell/config.yml

.PHONY: gitlab-spamcheck/config/config.toml
gitlab-spamcheck/config/config.toml:
	$(Q)rake gitlab-spamcheck/config/config.toml

.PHONY: grafana/grafana.ini
grafana/grafana.ini:
	$(Q)rake grafana/grafana.ini

.PHONY: nginx/conf/nginx.conf
nginx/conf/nginx.conf:
	$(Q)rake nginx/conf/nginx.conf

.PHONY: openssh/sshd_config
openssh/sshd_config:
	$(Q)rake openssh/sshd_config

.PHONY: prometheus/prometheus.yml
prometheus/prometheus.yml:
	$(Q)rake prometheus/prometheus.yml

.PHONY: redis/redis.conf
redis/redis.conf:
	$(Q)rake redis/redis.conf

.PHONY: registry/config.yml
registry/config.yml: registry_host.crt
	$(Q)rake registry/config.yml

.PHONY: snowplow/snowplow_micro.conf
snowplow/snowplow_micro.conf:
	$(Q)rake snowplow/snowplow_micro.conf

.PHONY: snowplow/iglu.json
snowplow/iglu.json:
	$(Q)rake snowplow/iglu.json

.PHONY: clickhouse/config.xml
clickhouse/config.xml:
	$(Q)rake clickhouse/config.xml

.PHONY: clickhouse/users.xml
clickhouse/users.xml:
	$(Q)rake clickhouse/users.xml

.PHONY: clickhouse/config.d/data-paths.xml
clickhouse/config.d/data-paths.xml:
	$(Q)rake clickhouse/config.d/data-paths.xml

.PHONY: clickhouse/config.d/gdk.xml
clickhouse/config.d/gdk.xml:
	$(Q)rake clickhouse/config.d/gdk.xml

.PHONY: clickhouse/config.d/logger.xml
clickhouse/config.d/logger.xml:
	$(Q)rake clickhouse/config.d/logger.xml

.PHONY: clickhouse/config.d/openssl.xml
clickhouse/config.d/openssl.xml:
	$(Q)rake clickhouse/config.d/openssl.xml

.PHONY: clickhouse/config.d/user-directories.xml
clickhouse/config.d/user-directories.xml:
	$(Q)rake clickhouse/config.d/user-directories.xml

.PHONY: clickhouse/users.d/gdk.xml
clickhouse/users.d/gdk.xml:
	$(Q)rake clickhouse/users.d/gdk.xml

.PHONY: elasticsearch/config/elasticsearch.yml
elasticsearch/config/elasticsearch.yml:
ifeq ($(elasticsearch_enabled),true)
	$(Q)rake elasticsearch/config/elasticsearch.yml
else
	@true
endif

.PHONY: elasticsearch/config/jvm.options.d/custom.options
elasticsearch/config/jvm.options.d/custom.options:
ifeq ($(elasticsearch_enabled),true)
	$(Q)rake elasticsearch/config/jvm.options.d/custom.options
else
	@true
endif

.PHONY: pgbouncers/pgbouncer-replica-1.ini
pgbouncers/pgbouncer-replica-1.ini:
	$(Q)rake pgbouncers/pgbouncer-replica-1.ini

.PHONY: pgbouncers/pgbouncer-replica-2.ini
pgbouncers/pgbouncer-replica-2.ini:
	$(Q)rake pgbouncers/pgbouncer-replica-2.ini

.PHONY: pgbouncers/pgbouncer-replica-2-1.ini
pgbouncers/pgbouncer-replica-2-1.ini:
	$(Q)rake pgbouncers/pgbouncer-replica-2-1.ini

.PHONY: pgbouncers/pgbouncer-replica-2-2.ini
pgbouncers/pgbouncer-replica-2-2.ini:
	$(Q)rake pgbouncers/pgbouncer-replica-2-2.ini

.PHONY: pgbouncers/userlist.txt
pgbouncers/userlist.txt:
	$(Q)rake pgbouncers/userlist.txt

.PHONY: consul/config.json
consul/config.json:
	$(Q)rake consul/config.json

.PHONY: gitlab-db-migrate
gitlab-db-migrate: ensure-databases-running
	$(Q)rake gitlab-db-migrate

.PHONY: preflight-checks
preflight-checks: preflight-checks-timed

.PHONY: preflight-checks-run
preflight-checks-run: rake
	$(Q)rake preflight-checks

.PHONY: preflight-update-checks
preflight-update-checks: preflight-update-checks-timed

.PHONY: preflight-update-checks-run
preflight-update-checks-run: rake
	$(Q)rake preflight-update-checks

.PHONY: gitaly/gitaly.config.toml
gitaly/gitaly.config.toml:
	$(Q)rake gitaly/gitaly.config.toml

.PHONY: gitaly/praefect.config.toml
gitaly/praefect.config.toml:
	$(Q)rake gitaly/praefect.config.toml

