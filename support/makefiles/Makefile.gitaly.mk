gitaly_clone_dir = gitaly
gitaly_version = $(shell support/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITALY_SERVER_VERSION")

gitaly-setup: ${gitaly_build_bin_dir}/gitaly gitaly/gitaly.config.toml gitaly/praefect.config.toml

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

	@echo
	@echo "${DIVIDER}"
	@echo "Installing gitlab-org/gitaly Ruby gems"
	@echo "${DIVIDER}"
	${Q}$(support_bundle_install) $(gitlab_development_root)/$(gitaly_clone_dir)/ruby

.PHONY: praefect-migrate
praefect-migrate: postgresql-seed-praefect
	$(Q)support/migrate-praefect
