postgresql/geo: postgresql-geo/data postgresql/geo/port postgresql/geo/seed-data

postgresql-geo/data:
ifeq ($(geo_enabled), true)
ifeq ($(geo_secondary), true)
	$(Q)${postgresql_bin_dir}/initdb --locale=C -E utf-8 postgresql-geo/data
else
	@true
endif
endif

postgresql/geo/port: postgresql-geo/data
ifeq ($(geo_enabled), true)
ifeq ($(geo_secondary), true)
	$(Q)support/postgres-port ${postgresql_geo_dir} ${postgresql_geo_port} 'postgresql-geo'
else
	@true
endif
endif

postgresql/geo/Procfile:
	$(Q)grep '^postgresql-geo:' Procfile || (printf ',s/^#postgresql-geo/postgresql-geo/\nwq\n' | ed -s Procfile)

postgresql/geo/seed-data:
ifeq ($(geo_enabled), true)
ifeq ($(geo_secondary), true)
	$(Q)support/bootstrap-geo
else
	@true
endif
endif

postgresql-geo-replication-primary: postgresql-replication/config

postgresql-geo-replication-secondary: postgresql-geo-secondary-replication/data postgresql-replication/backup postgresql-replication/config

postgresql-geo-secondary-replication/data:
	${postgresql_bin_dir}/initdb --locale=C -E utf-8 ${postgresql_data_dir}
