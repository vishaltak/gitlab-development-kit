.PHONY: postgresql
postgresql: postgresql/data postgresql/port

postgresql/data:
	@echo
	@echo "${DIVIDER}"
	@echo "PostgreSQL: Creating DB in ${postgresql_data_dir}"
	@echo "${DIVIDER}"
	$(Q)${postgresql_bin_dir}/initdb --locale=C -E utf-8 ${postgresql_data_dir} ${QQ}

postgresql/port:
	$(Q)support/postgres-port ${postgresql_dir} ${postgresql_port}

postgresql-sensible-defaults:
	$(Q)support/postgresql-sensible-defaults ${postgresql_dir}
