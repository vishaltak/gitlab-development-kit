.NOTPARALLEL:

START_TIME := $(shell date "+%s")

DIVIDER = "--------------------------------------------------------------------------------"

SHELL = /bin/bash
ASDF := $(shell command -v asdf 2> /dev/null)
RAKE := $(shell command -v rake 2> /dev/null)
BUNDLE := $(shell command -v bundle 2> /dev/null)
YARN := $(shell command -v yarn 2> /dev/null)

# Speed up Go module downloads
export GOPROXY ?= https://proxy.golang.org

# Silence Rollup when building GitLab Docs with nanoc
export ROLLUP_OPTIONS = --silent

NO_RAKE_REQUIRED := bootstrap lint

# Generate a Makefile from Ruby and include it
ifdef RAKE
ifeq (,$(filter $(NO_RAKE_REQUIRED), $(MAKECMDGOALS)))
include $(shell rake gdk-config.mk)
endif
else
ifeq (,$(filter $(NO_RAKE_REQUIRED), $(MAKECMDGOALS)))
$(error "ERROR: Cannot find 'rake'. Please run 'make bootstrap'.")
endif
endif

ifeq ($(platform),darwin)
OPENSSL_PREFIX := $(shell brew --prefix openssl)
OPENSSL := ${OPENSSL_PREFIX}/bin/openssl
else
OPENSSL := $(shell command -v openssl 2> /dev/null)
endif

bundle_install_cmd = ${BUNDLE} install --jobs 4 ${BUNDLE_ARGS}

# Borrowed from https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/Makefile#n87
#
ifeq ($(gdk_debug),true)
	Q =
	QQ =
else
	Q = @
	QQ = > /dev/null
endif

QQerr = 2> /dev/null

ifeq ($(shallow_clone),true)
git_depth_param = --depth=1
endif

# This is used by 'gdk install' and 'gdk reconfigure'
#
.PHONY: all
all: preflight-checks \
common-setup-and-update-pre-tasks \
gitlab-setup-minimal \
gitlab-shell-setup \
gitaly-setup \
ensure-data-services-running \
gitlab-setup \
common-setup-and-update-tasks \
gitlab-workhorse-setup \
gitlab-pages-setup \
gitlab-k8s-agent-setup \
gitlab-ui-setup \
gitlab-docs-setup \
gitlab-spamcheck-setup \
gitlab-elasticsearch-indexer-setup

# These are used by both 'gdk install' and 'gdk update'
#
.PHONY: common-setup-and-update-pre-tasks
common-setup-and-update-pre-tasks: Procfile redis postgresql ensure-required-ruby-bundlers-installed unlock-dependency-installers ensure-db-services-running

.PHONY: common-setup-and-update-tasks
common-setup-and-update-tasks: geo-config runner-setup openssh-setup nginx-setup registry-setup prom-setup jaeger-setup object-storage-setup grafana-setup elasticsearch-setup

# This is used by 'gdk install'
#
.PHONY: install
install: all show-installed-at start

# This is used by 'gdk update'
#
# Pull gitlab directory first since dependencies are linked from there.
.PHONY: update
update: asdf-update \
preflight-checks \
preflight-update-checks \
common-setup-and-update-pre-tasks \
gitlab-update-minimal \
gitlab-shell-update \
gitaly-update \
ensure-data-services-running \
gitlab-update-without-pull \
common-setup-and-update-tasks \
gitlab-workhorse-update \
gitlab-pages-update \
gitlab-k8s-agent-update \
gitlab-ui-update \
gitlab-docs-update \
gitlab-spamcheck-update \
gitlab-elasticsearch-indexer-update \
update-summarize

.PHONY: update-summarize
update-summarize:
	@echo
	@echo "${DIVIDER}"
	@echo "Updated successfully as of $$(date +"%Y-%m-%d %T")"
	@echo "${DIVIDER}"

# This is used by `gdk reconfigure`
#
.PHONY: reconfigure
reconfigure: ensure-required-ruby-bundlers-installed \
unlock-dependency-installers \
postgresql-sensible-defaults \
touch-examples \
Procfile \
update-runit-services \
all \
show-reconfigured-at

.PHONY: update-runit-services
update-runit-services:
	@support/runit-update-services

.PHONY: clean
clean:
	@true

.PHONY: self-update
self-update: unlock-dependency-installers
	@echo
	@echo "${DIVIDER}"
	@echo "Running self-update on GDK"
	@echo "${DIVIDER}"
	$(Q)git stash ${QQ}
	$(Q)support/self-update-git-worktree ${QQ}

.PHONY: touch-examples
touch-examples:
	$(Q)touch \
	gitlab-shell/config.yml.example \
	gitlab/workhorse/config.toml.example \
	$$(find support/templates -name "*.erb")

unlock-dependency-installers:
	$(Q)rm -f \
	.gitlab-bundle \
	.gitlab-yarn \
	.gitlab-ui-yarn

gdk.yml:
	$(Q)touch $@

.PHONY: Procfile
Procfile:
	$(Q)rake $@

.PHONY: rake
rake:
	$(Q)command -v $@ ${QQ} || gem install $@

.PHONY: ensure-db-services-running-tasks
ensure-db-services-tasks: Procfile postgresql redis

.PHONY: ensure-db-services-running
ensure-db-services-running: ensure-db-services-tasks
	$(Q)gdk start db ${QQ}

.PHONY: ensure-data-services-running
ensure-data-services-running: ensure-db-services-tasks
	$(Q)gdk start rails-migration-dependencies ${QQ}

.PHONY: check-if-services-running/%
check-if-services-running/%:
	$(Q)support/check_services_running $* || (echo "ERROR: "$*" service(s) are not running." ; false)

.PHONY: ensure-required-ruby-bundlers-installed
ensure-required-ruby-bundlers-installed:
	@echo
	@echo "${DIVIDER}"
	@echo "GDK: Ensuring all required versions of bundler are installed"
	@echo "${DIVIDER}"
	${Q}. ./support/bootstrap-common.sh ; ruby_install_required_bundlers

.PHONY: diff-config
diff-config: touch-examples
	$(Q)gdk $@

.PHONY: start
start:
	@echo
	$(Q)gdk start

.PHONY: show-installed-at
show-installed-at:
	@echo
	@echo "> Installed as of $$(date +"%Y-%m-%d %T"). Took $$(($$(date +%s)-${START_TIME})) second(s)."

.PHONY: show-reconfigured-at
show-reconfigured-at:
	@echo
	@echo "> Reconfigured as of $$(date +"%Y-%m-%d %T"). Took $$(($$(date +%s)-${START_TIME})) second(s)."

###############################################################################
# Include all support/makefiles/*.mk files here                               #
###############################################################################

include support/makefiles/*.mk
