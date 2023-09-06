gitaly_clone_dir = gitaly
gitaly_version = $(shell support/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITALY_SERVER_VERSION")

ifeq ($(SKIP_GITALY_SETUP),true)
gitaly-setup:
	@echo
	@echo "${DIVIDER}"
	@echo "Skipping gitaly setup due to environment variable SKIP_GITALY_SETUP set to true"
	@echo "${DIVIDER}"
else
gitaly-setup: ${gitaly_build_bin_dir}/gitaly gitaly/gitaly.config.toml gitaly/praefect.config.toml
endif

${gitaly_clone_dir}/.git:
	$(Q)if [ -e gitaly ]; then mv gitaly .backups/$(shell date +gitaly.old.%Y-%m-%d_%H.%M.%S); fi
	$(Q)support/component-git-clone ${gitaly_repo} ${gitaly_clone_dir}
	$(Q)support/component-git-update gitaly "${gitaly_clone_dir}" "${gitaly_version}" master

.PHONY: gitaly-update
gitaly-update: gitaly-update-timed

.PHONY: gitaly-update-run
gitaly-update-run: gitaly-git-pull gitaly-setup praefect-migrate

.PHONY: gitaly-git-pull
gitaly-git-pull: gitaly-git-pull-timed

.PHONY: gitaly-git-pull-run
gitaly-git-pull-run: ${gitaly_clone_dir}/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitaly to ${gitaly_version}"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitaly "${gitaly_clone_dir}" "${gitaly_version}" master

.PHONY: ${gitaly_build_bin_dir}/gitaly
${gitaly_build_bin_dir}/gitaly: ${gitaly_clone_dir}/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Building gitlab-org/gitaly ${gitaly_version}"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec ${gitaly_clone_dir} $(MAKE) -j${restrict_cpu_count} WITH_BUNDLED_GIT=YesPlease BUNDLE_FLAGS=--no-deployment

.PHONY: praefect-migrate
praefect-migrate: _postgresql-seed-praefect
	$(Q)support/migrate-praefect
