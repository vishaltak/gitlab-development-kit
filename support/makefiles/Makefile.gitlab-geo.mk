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
geo-primary-migrate: geo-primary-migrate-timed

.PHONY: geo-primary-migrate-run
geo-primary-migrate-run: ensure-databases-running .gitlab-bundle gitlab-db-migrate gitlab/git-restore diff-config

.PHONY: geo-primary-update
geo-primary-update: update geo-primary-migrate diff-config

.PHONY: geo-secondary-migrate
geo-secondary-migrate: ensure-databases-running .gitlab-bundle gitlab-db-migrate gitlab/git-restore

.PHONY: geo-secondary-update
geo-secondary-update: geo-secondary-update-timed

.PHONY: geo-secondary-update-run
geo-secondary-update-run: update geo-secondary-migrate diff-config
