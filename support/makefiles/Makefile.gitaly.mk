gitaly_clone_dir = gitaly
gitaly_version = $(shell support/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITALY_SERVER_VERSION")
gitaly_bin_cached_version = ${gitlab_development_cache_root}/.gitaly_bin_${gitaly_version}
gitaly_git_bin_cached_version = ${gitlab_development_cache_root}/.gitaly_git_bin_${gitaly_version}

################################################################################
# Main
#
.PHONY: gitaly
gitaly: gitaly-setup

################################################################################
# Setup/update/fresh
#
.PHONY: gitaly-setup
gitaly-setup: gitaly-pre-tasks ${gitaly_clone_dir}/.git gitaly-post-tasks gitaly-praefect-db-bootstrap

.PHONY: gitaly-update
gitaly-update: gitaly-update-pre-tasks gitaly-tests-clean gitaly-git-pull gitaly-post-tasks gitaly-praefect-db-migrate

.PHONY: gitaly-fresh
gitaly-fresh: gitaly-clean gitaly-update

################################################################################
# Pre/post tasks
#
.PHONY: gitaly-pre-tasks
gitaly-pre-tasks: gitaly-inform

.PHONY: gitaly-update-pre-tasks
gitaly-update-pre-tasks: gitaly-pre-tasks check-if-services-running/db

.PHONY: gitaly-post-tasks
gitaly-post-tasks: gitaly-build gitaly/gitaly.config.toml gitaly/praefect.config.toml

################################################################################
# Git
#
${gitaly_clone_dir}/.git:
	$(Q)support/component-git-update gitaly "${gitaly_clone_dir}" "${gitaly_version}" master ${git_depth_param}

.PHONY: gitaly-git-pull
gitaly-git-pull:
	$(Q)support/component-git-update gitaly "${gitaly_clone_dir}" "${gitaly_version}" master

################################################################################
# Files
#
${gitaly_bin_cached_version}:
	$(Q)$(MAKE) -C ${gitaly_clone_dir} BUNDLE_FLAGS=--no-deployment
	$(Q)cd ${gitlab_development_root}/gitaly/ruby && $(bundle_install_cmd)
	@mkdir -p ${gitlab_development_cache_root}
	$(Q)touch $@

${gitaly_git_bin_cached_version}:
	$(Q)$(MAKE) -C ${gitaly_clone_dir} git
	@mkdir -p ${gitlab_development_cache_root}
	$(Q)touch $@

.PHONY: gitaly/gitaly.config.toml
gitaly/gitaly.config.toml:
	$(Q)rake $@

.PHONY: gitaly/praefect.config.toml
gitaly/praefect.config.toml:
	$(Q)rake $@

################################################################################
# Inform
#
.PHONY: gitaly-inform
gitaly-inform:
	@echo
	@echo "${DIVIDER}"
	@echo "gitaly: Updating git repo to ${gitaly_version}"
	@echo "${DIVIDER}"

.PHONY: gitaly-inform-build
gitaly-inform-build:
	@echo
	@echo "${DIVIDER}"
	@echo "gitaly: Building ${gitaly_version} as well as git"
	@echo "${DIVIDER}"

################################################################################
# Clean
#
.PHONY: gitaly-tests-clean
gitaly-tests-clean:
	$(Q)rm -rf ${gitlab_development_root}/gitlab/tmp/tests/gitaly

.PHONY: gitaly-clean
gitaly-clean: gitaly-tests-clean
	$(Q)rm -rf ${gitlab_development_cache_root}/.gitaly_*

################################################################################

.PHONY: gitaly-build
gitaly-build: gitaly-inform-build ${gitaly_bin_cached_version} ${gitaly_git_bin_cached_version}

.PHONY: gitaly-praefect-db-bootstrap
gitaly-praefect-db-bootstrap: check-if-services-running/db
	@echo
	@echo "${DIVIDER}"
	@echo "gitaly: Bootstrapping praefect"
	@echo "${DIVIDER}"
	$(Q)support/bootstrap-praefect

.PHONY: gitaly-praefect-db-migrate
gitaly-praefect-db-migrate: check-if-services-running/db
	@echo
	@echo "${DIVIDER}"
	@echo "gitaly: Migrating praefect"
	@echo "${DIVIDER}"
	$(Q)support/migrate-praefect
