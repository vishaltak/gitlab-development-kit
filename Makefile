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
.PHONY: all
all: preflight-checks \
_unlock-dependency-installers \
gitlab-setup \
gitaly-setup \
_support-setup \
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
.PHONY: update
update: start-task \
platform-update \
preflight-checks \
preflight-update-checks \
_unlock-dependency-installers \
gitlab-update \
gitaly-update \
_support-setup \
geo-config \
gitlab-docs-update \
gitlab-elasticsearch-indexer-update \
gitlab-k8s-agent-update \
gitlab-metrics-exporter-update \
gitlab-pages-update \
gitlab-spamcheck-update \
gitlab-shell-update \
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
_unlock-dependency-installers \
_support-setup \
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

self-update:
	@echo
	@echo "${DIVIDER}"
	@echo "Running self-update on GDK"
	@echo "${DIVIDER}"
	$(Q)git stash ${QQ}
	$(Q)support/self-update-git-worktree ${QQ}

.PHONY: _touch-examples
_touch-examples:
	$(Q)touch \
	gitlab-shell/config.yml.example \
	gitlab/workhorse/config.toml.example \
	$$(find support/templates -name "*.erb" -not -path "*/gitlab-pages-secret.erb") > /dev/null 2>&1 || true

_unlock-dependency-installers:
	$(Q)rm -f \
	.gdk-configs-update-all \
	.gdk-configs-to-update \
	.gitlab-bundle \
	.gitlab-gdk-gem \
	.gitlab-lefthook \
	.gitlab-shell-bundle \
	.gitlab-yarn \
	.gitlab-ui-yarn

gdk.yml:
	$(Q)touch $@

.PHONY: rake
rake:
	$(Q)command -v $@ ${QQ} || gem install $@

.PHONY: _ensure-databases-setup
_ensure-databases-setup: postgresql/data ensure-databases-running

.PHONY: ensure-databases-running
ensure-databases-running:
	@echo
	@echo "${DIVIDER}"
	@echo "Ensuring necessary data services are running"
	@echo "${DIVIDER}"
	$(Q)gdk start rails-migration-dependencies

.PHONY: diff-config
diff-config:
	$(Q)gdk $@

.PHONY: _support-setup
_support-setup: \
_touch-examples \
_unlock-dependency-installers \
_gdk-clear-needed-configs \
\
_nginx-configs \
_openssh-configs \
_registry-configs \
\
_gdk-update-needed-configs \
\
_ensure-databases-setup \
postgresql \
elasticsearch-setup \
runner-setup \
\
_jaeger-setup \
_nginx-setup \
_openssh-setup \
_registry-setup

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

.PHONY: _gdk-clear-needed-configs
_gdk-clear-needed-configs:
	${Q}rm -f tmp/.gdk-configs-to-update

.PHONY: _gdk-update-needed-configs
_gdk-update-needed-configs:
	${Q}sort tmp/.gdk-configs-to-update | uniq | xargs rake
	${Q}rm -f tmp/.gdk-configs-to-update

.gdk-configs-update-all:
	@echo
	@echo "${DIVIDER}"
	@echo "Ensuring GDK managed configuration files are up-to-date"
	@echo "${DIVIDER}"
	$(Q)rake reconfigure
	$(Q)touch $@
