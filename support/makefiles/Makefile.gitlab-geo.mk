.PHONY: geo-secondary-setup geo-cursor
geo-secondary-setup: geo-setup-check Procfile geo-cursor geo-config postgresql/geo

geo-setup-check:
ifneq ($(geo_enabled),true)
	$(Q)echo 'ERROR: geo.enabled is not set to true in your gdk.yml'
	@exit 1
else
	@true
endif

geo-config: gitlab/config/database.yml postgresql/geo/port

geo-cursor:
	$(Q)grep '^geo-cursor:' Procfile || (printf ',s/^#geo-cursor/geo-cursor/\nwq\n' | ed -s Procfile)

.PHONY: geo-primary-migrate
geo-primary-migrate: geo-primary-migrate-timed

.PHONY: geo-primary-migrate-run
geo-primary-migrate-run: ensure-databases-running .gitlab-bundle gitlab-db-migrate gitlab/git-checkout-auto-generated-files diff-config

.PHONY: geo-primary-update
geo-primary-update: update geo-primary-migrate diff-config

.PHONY: geo-secondary-migrate
geo-secondary-migrate: ensure-databases-running .gitlab-bundle gitlab-db-migrate gitlab/git-checkout-auto-generated-files

.PHONY: geo-secondary-update
geo-secondary-update: geo-secondary-update-timed

.PHONY: geo-secondary-update-run
geo-secondary-update-run: update geo-secondary-migrate diff-config
