gitlab_clone_dir = gitlab
in_gitlab = cd $(gitlab_development_root)/$(gitlab_clone_dir) &&
gitlab_rake_cmd = $(in_gitlab) ${support_bundle_exec} rake

GDK_CACHE_DIR := $(gitlab_development_root)/.cache
FLAG_FILE := $(GDK_CACHE_DIR)/.truncate_tables
ci_database_enabled = $(shell gdk config get gitlab.rails.databases.ci.enabled 2>/dev/null)

.PHONY: truncate-legacy-tables
truncate-legacy-tables: ensure-databases-running start-truncate do-truncate

.PHONY: start-truncate
start-truncate:
	@echo
	@echo "${DIVIDER}"
	@echo "Ensuring legacy data in main & ci databases are truncated"
	@echo "${DIVIDER}"

.PHONY: do-truncate
do-truncate:
ifeq ($(ci_database_enabled),true)
ifeq ($(wildcard $(FLAG_FILE)),)
	$(Q)$(gitlab_rake_cmd) gitlab:db:lock_writes
	$(Q)$(gitlab_rake_cmd) gitlab:db:truncate_legacy_tables:main
	$(Q)$(gitlab_rake_cmd) gitlab:db:truncate_legacy_tables:ci
	$(Q)$(gitlab_rake_cmd) gitlab:db:unlock_writes

	@echo "Legacy data truncation completed!"

	@mkdir -p "${GDK_CACHE_DIR}"
	@touch $(FLAG_FILE)
else
	@echo "Databases are already truncated, nothing to do here"
endif
else
	@echo "CI database not enabled, nothing to do here"
endif
