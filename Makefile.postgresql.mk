.PHONY: postgresql
postgresql: postgresql/data postgresql/port postgresql-seed-rails postgresql-seed-praefect

postgresql/data:
	$(Q)${postgresql_bin_dir}/initdb --locale=C -E utf-8 ${postgresql_data_dir}

.PHONY: postgresql-seed-rails
postgresql-seed-rails: ensure-databases-running postgresql-seed-praefect
	$(Q)support/bootstrap-rails

.PHONY: postgresql-seed-praefect
postgresql-seed-praefect: Procfile postgresql/data postgresql-geo/data postgresql/geo/port
	$(Q)gdk start db
	$(Q)support/bootstrap-praefect

postgresql/port:
	$(Q)support/postgres-port ${postgresql_dir} ${postgresql_port}

postgresql-sensible-defaults:
	$(Q)support/postgresql-sensible-defaults ${postgresql_dir}
