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

# This is used by `gdk install` and `gdk reconfigure`
#
.PHONY: all
all: preflight-checks \
gitlab-setup \
gdk-reconfigure-task \
gitlab-shell-setup \
gitlab-workhorse-setup \
gitlab-pages-setup \
gitlab-k8s-agent-setup \
support-setup \
gitaly-setup \
geo-config \
openldap-setup \
prom-setup \
object-storage-setup \
gitlab-elasticsearch-indexer-setup \
zoekt-setup \
gitlab-metrics-exporter-setup \
grafana-setup \
gitlab-ui-setup \
gitlab-docs-setup \
gitlab-spamcheck-setup \
snowplow-micro-setup \
postgresql-sensible-defaults \

# This is used by `gdk install`
#
.PHONY: install
install: all post-install-tasks start

# This is used by `gdk update`
#
# Pull gitlab directory first since dependencies are linked from there.
.PHONY: update
update: update-start \
asdf-update \
preflight-checks \
preflight-update-checks \
gitlab-git-pull \
gitlab-bundle-prepare \
ensure-databases-running \
unlock-dependency-installers \
gitlab-translations-unlock \
gitlab-shell-update \
gitlab-workhorse-update \
gitlab-pages-update \
gitlab-k8s-agent-update \
gitaly-update \
gitlab-update \
gitlab-elasticsearch-indexer-update \
zoekt-update \
gitlab-metrics-exporter-update \
object-storage-update \
jaeger-update \
grafana-update \
gitlab-ui-update \
gitlab-docs-update \
gitlab-spamcheck-update \
post-update-tasks

.PHONY: update-start
update-start:
	@support/dev/makefile-timeit start

.PHONY: post-update-tasks
post-update-tasks:
	@echo
	@echo "${DIVIDER}"
	@echo "Timings"
	@echo "${DIVIDER}"
	@echo
	@support/dev/makefile-timeit summarize
	@echo
	@echo "${DIVIDER}"
	@echo "Updated successfully as of $$(date +"%Y-%m-%d %T")"
	@echo "${DIVIDER}"

# This is used by `gdk reconfigure`
#
.PHONY: reconfigure
reconfigure: unlock-dependency-installers \
touch-examples \
all \
post-reconfigure-tasks

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

support-setup: Procfile gitaly-setup jaeger-setup postgresql openssh-setup nginx-setup registry-setup elasticsearch-setup runner-setup

.PHONY: start
start:
	@echo
	$(Q)gdk start

.PHONY: ask-to-restart
ask-to-restart:
	@echo
	$(Q)support/ask-to-restart
	@echo

.PHONY: post-install-tasks
post-install-tasks: display-announcement_doubles-for-user
	@echo
	@echo "> Installed as of $$(date +"%Y-%m-%d %T"). Took $$(($$(date +%s)-${START_TIME})) second(s)."

.PHONY: post-reconfigure-tasks
post-reconfigure-tasks: display-announcement_doubles-for-user
	@echo
	@echo "> Reconfigured as of $$(date +"%Y-%m-%d %T"). Took $$(($$(date +%s)-${START_TIME})) second(s)."

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
