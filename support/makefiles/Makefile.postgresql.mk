.PHONY: postgresql
postgresql: postgresql/data postgresql/port _postgresql-seed-dbs

postgresql/data:
	$(Q)${postgresql_bin_dir}/initdb --locale=C -E utf-8 ${postgresql_data_dir}

.PHONY: _postgresql-seed-dbs
_postgresql-seed-dbs: _postgresql-seed-dbs-heading _postgresql-seed-praefect _postgresql-seed-rails

.PHONY: _postgresql-seed-dbs-heading
_postgresql-seed-dbs-heading:
	@echo
	@echo "${DIVIDER}"
	@echo "Ensuring necessary databases are setup and seeded"
	@echo "${DIVIDER}"

.PHONY: _posgresql-environment
_postgresql-environment: Procfile postgresql/data postgresql-geo/data postgresql/geo/port
	$(Q)gdk start db --quiet

.PHONY: _postgresql-seed-rails
_postgresql-seed-rails: _postgresql-environment
	$(Q)support/bootstrap-rails

.PHONY: _postgresql-seed-praefect
_postgresql-seed-praefect: _postgresql-environment
ifeq ($(praefect_enabled), true)
	$(Q)support/bootstrap-praefect
else
	@true
endif

postgresql/port:
	$(Q)support/postgres-port ${postgresql_dir} ${postgresql_port}

postgresql-sensible-defaults:
	$(Q)support/postgresql-sensible-defaults ${postgresql_dir}
