.NOTPARALLEL:

START_TIME := $(shell date "+%s")

MAKEFLAGS += --no-print-directory

DIVIDER = "--------------------------------------------------------------------------------"

SHELL = bin/gdk-shell
ASDF := $(shell command -v asdf 2> /dev/null)
RAKE := $(shell command -v rake 2> /dev/null)
BUNDLE := $(shell command -v bundle 2> /dev/null)
YARN := $(shell command -v yarn 2> /dev/null)

# Speed up Go module downloads
export GOPROXY ?= https://proxy.golang.org

# Silence Rollup when building GitLab Docs with nanoc
export ROLLUP_OPTIONS = --silent

NO_RAKE_REQUIRED := bootstrap bootstrap-packages lint

# Generate a Makefile from Ruby and include it
ifeq (,$(filter $(NO_RAKE_REQUIRED), $(MAKECMDGOALS)))
ifdef RAKE
include $(shell rake gdk-config.mk)
else
$(error "ERROR: Cannot find 'rake'. Please run 'make bootstrap'.")
endif
endif

export GDK_QUIET = $(gdk_quiet)

###############################################################################
# Include all support/makefiles/*.mk files here                               #
###############################################################################

include support/makefiles/*.mk

ifeq ($(platform),darwin)
OPENSSL_PREFIX := $(shell brew --prefix openssl@1.1)
OPENSSL := ${OPENSSL_PREFIX}/bin/openssl
else
OPENSSL := $(shell command -v openssl 2> /dev/null)
endif

support_bundle_install = $(gitlab_development_root)/support/bundle-install
support_bundle_exec = $(gitlab_development_root)/support/bundle-exec

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

# This is used by `gdk install`
#
# The 'ensure-databases-running' target performs 'gitaly-update` and verifies that all necessary data services are running.
.PHONY: all
all: preflight-checks \
gitlab-setup \
gitaly-setup \
ensure-databases-running \
gdk-reconfigure-task \
support-setup \
geo-config \
gitlab-docs-setup \
gitlab-elasticsearch-indexer-setup \
gitlab-k8s-agent-setup \
gitlab-metrics-exporter-setup \
gitlab-pages-setup \
gitlab-shell-setup \
gitlab-spamcheck-setup \
gitlab-ui-setup \
gitlab-workhorse-setup \
grafana-setup \
object-storage-setup \
openldap-setup \
prom-setup \
snowplow-micro-setup \
zoekt-setup \
postgresql-sensible-defaults

# This is used by `gdk install`
#
.PHONY: install
install: start-task all post-install-task start

# This is used by `gdk update`
#
# Pull `gitlab` directory first, since its dependencies are linked from there.
# The 'ensure-databases-running' target performs 'gitaly-update` and verifies that all necessary data services are running.
.PHONY: update
update: start-task \
asdf-update \
preflight-checks \
preflight-update-checks \
ensure-databases-running \
unlock-dependency-installers \
gitlab-update \
gitlab-docs-update \
gitlab-elasticsearch-indexer-update \
gitlab-k8s-agent-update \
gitlab-metrics-exporter-update \
gitlab-pages-update \
gitlab-shell-update \
gitlab-spamcheck-update \
gitlab-translations-unlock \
gitlab-ui-update \
gitlab-workhorse-update \
grafana-update \
jaeger-update \
object-storage-update \
zoekt-update \
post-update-task

# This is used by `gdk reconfigure`
#
.PHONY: reconfigure
reconfigure: start-task \
touch-examples \
gdk-reconfigure-task \
support-setup \
geo-config \
gitlab-docs-setup \
gitlab-elasticsearch-indexer-setup \
gitlab-k8s-agent-setup \
gitlab-metrics-exporter-setup \
gitlab-pages-setup \
gitlab-spamcheck-setup \
gitlab-ui-setup \
grafana-setup \
object-storage-setup \
openldap-setup \
postgresql-sensible-defaults \
prom-setup \
snowplow-micro-setup \
zoekt-setup \
post-reconfigure-task

.PHONY: start-task
start-task:
	@support/dev/makefile-timeit start

.PHONY: post-task
post-task:
	@echo
	@echo "${DIVIDER}"
	@echo "Timings"
	@echo "${DIVIDER}"
	@echo
	@support/dev/makefile-timeit summarize
	@echo
	@echo "${DIVIDER}"
	@echo "$(SUCCESS_MESSAGE) successfully as of $$(date +"%Y-%m-%d %T")"
	@echo "${DIVIDER}"

.PHONY: post-install-task
post-install-task: display-announcement_doubles-for-user
	$(Q)$(eval SUCCESS_MESSAGE := "Installed")
	$(Q)$(MAKE) post-task SUCCESS_MESSAGE="$(SUCCESS_MESSAGE)"

.PHONY: post-update-task
post-update-task:
	$(Q)$(eval SUCCESS_MESSAGE := "Updated")
	$(Q)$(MAKE) post-task SUCCESS_MESSAGE="$(SUCCESS_MESSAGE)"

.PHONY: post-reconfigure-task
post-reconfigure-task: display-announcement_doubles-for-user
	$(Q)$(eval SUCCESS_MESSAGE := "Reconfigured")
	$(Q)$(MAKE) post-task SUCCESS_MESSAGE="$(SUCCESS_MESSAGE)"

.PHONY: clean
clean:
	@true

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
	$$(find support/templates -name "*.erb" -not -path "*/gitlab-pages-secret.erb") > /dev/null 2>&1 || true

unlock-dependency-installers:
	$(Q)rm -f \
	.gitlab-bundle \
	.gitlab-shell-bundle \
	.gitlab-yarn \
	.gitlab-ui-yarn \
	.gitlab-gdk-gem \
	.gitlab-lefthook

gdk.yml:
	$(Q)touch $@

.PHONY: rake
rake:
	$(Q)command -v $@ ${QQ} || gem install $@

.PHONY: ensure-databases-running
ensure-databases-running: Procfile postgresql/data gitaly-update
	@echo
	@echo "${DIVIDER}"
	@echo "Ensuring necessary data services are running"
	@echo "${DIVIDER}"
	$(Q)gdk start rails-migration-dependencies

.PHONY: diff-config
diff-config: touch-examples
	$(Q)gdk $@

support-setup: Procfile jaeger-setup postgresql openssh-setup nginx-setup registry-setup elasticsearch-setup runner-setup

.PHONY: start
start:
	@echo
	$(Q)gdk start

.PHONY: ask-to-restart
ask-to-restart:
	@echo
	$(Q)support/ask-to-restart
	@echo

.PHONY: display-announcement_doubles-for-user
display-announcement_doubles-for-user:
	@support/announcements-display

.PHONY: gdk-reconfigure-task
gdk-reconfigure-task:
	@echo
	@echo "${DIVIDER}"
	@echo "Ensuring GDK managed configuration files are up-to-date"
	@echo "${DIVIDER}"
	$(Q)rake reconfigure
