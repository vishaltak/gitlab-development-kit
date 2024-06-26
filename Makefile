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
export GOPROXY ?= https://proxy.golang.org|https://proxy.golang.org

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
# https://git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt
git_params = --depth=1
else ifeq ($(blobless_clone),false)
git_params =
else
# https://git-scm.com/docs/git-clone#Documentation/git-clone.txt---filterltfilter-specgt
git_params = --filter=blob:none
endif

# List Makefile targets
.PHONY: list
list:
	@make -qp | awk -F':' '/^[a-zA-Z0-9][^$$#\/\t=]*:([^=]|$$)/ {split($$1,A,/ /);for(i in A)print A[i]}' | sort -u

# This is used by `gdk install`
#
# When GitLab boots, it checks to ensure the version of gitlab-shell it expects
# (based off of https://gitlab.com/gitlab-org/gitlab/-/blob/b99664deef4af88ef33bcd0abef8b0845a81e00f/GITLAB_SHELL_VERSION)
# matches what's checkout under <GDK_ROOT>/gitlab-shell (https://gitlab.com/gitlab-org/gitlab/-/blob/b99664deef4af88ef33bcd0abef8b0845a81e00f/config/initializers/5_backend.rb#L8).
# We run gitlab-shell-setup here before gitlab-setup to ensure GitLab is happy.
# We also need to run gitlab/.git _prior_ to gitlab-shell-setup because it
# needs access to <GDK_ROOT>/gitlab/GITLAB_SHELL_VERSION
#
.PHONY: all
all: preflight-checks \
gdk_bundle_install \
gitlab/.git \
gitlab-shell-setup \
gitlab-setup \
gitaly-setup \
ensure-databases-setup \
gdk-reconfigure-task \
Procfile \
jaeger-setup \
postgresql \
openssh-setup \
nginx-setup \
registry-setup \
elasticsearch-setup \
runner-setup \
geo-config \
gitlab-docs-setup \
gitlab-elasticsearch-indexer-setup \
gitlab-k8s-agent-setup \
gitlab-pages-setup \
gitlab-spamcheck-setup \
gitlab-ui-setup \
gitlab-workhorse-setup \
gitlab-zoekt-indexer-setup \
grafana-setup \
object-storage-setup \
openldap-setup \
pgvector-setup \
prom-setup \
snowplow-micro-setup \
zoekt-setup \
postgresql-sensible-defaults \
postgresql-replica-setup \
postgresql-replica-2-setup

# This is used by `gdk install`
#
.PHONY: install
install: start-task all post-install-task start

# This is used by `gdk update`
#
# Pull `gitlab` directory first, since its dependencies are linked from there.
.PHONY: update
update: start-task \
gdk_bundle_install \
gitlab/.git/pull \
gitlab-update \
platform-update \
preflight-checks \
preflight-update-checks \
gitaly-update \
ensure-databases-setup \
gitlab-shell-update \
unlock-dependency-installers \
gitlab-docs-update \
gitlab-elasticsearch-indexer-update \
gitlab-k8s-agent-update \
gitlab-pages-update \
gitlab-spamcheck-update \
gitlab-translations-unlock \
gitlab-ui-update \
gitlab-workhorse-update \
gitlab-zoekt-indexer-update \
grafana-update \
jaeger-update \
object-storage-update \
pgvector-update \
zoekt-update \
post-update-task

# This is used by `gdk reconfigure`
#
.PHONY: reconfigure
reconfigure: start-task reconfigure-tasks post-reconfigure-task

.PHONY: reconfigure-tasks
reconfigure-tasks: \
gdk-reconfigure-task \
Procfile \
jaeger-setup \
postgresql \
openssh-setup \
nginx-setup \
registry-setup \
elasticsearch-setup \
runner-setup \
geo-config \
gitlab-docs-setup \
gitlab-elasticsearch-indexer-setup \
gitlab-k8s-agent-setup \
gitlab-pages-setup \
gitlab-spamcheck-setup \
gitlab-ui-setup \
gitlab-zoekt-indexer-setup \
grafana-setup \
object-storage-setup \
openldap-setup \
pgvector-setup \
postgresql-sensible-defaults \
prom-setup \
snowplow-micro-setup \
zoekt-setup \
postgresql-replica-setup \
postgresql-replica-2-setup

.PHONY: start-task
start-task:
	@support/dev/makefile-timeit start

.PHONY: post-task
post-task:
	@echo
	@echo "${DIVIDER}"
	@echo "$(SUCCESS_MESSAGE) successfully as of $$(date +"%Y-%m-%d %T")"
	@support/dev/makefile-timeit summarize
	@echo "${DIVIDER}"

.PHONY: post-install-task
post-install-task: display-announcement_doubles-for-user
	$(Q)$(eval SUCCESS_MESSAGE := "Installed")
	$(Q)$(MAKE) post-task SUCCESS_MESSAGE="$(SUCCESS_MESSAGE)"

.PHONY: post-update-task
post-update-task: display-announcement_doubles-for-user
	$(Q)$(eval SUCCESS_MESSAGE := "Updated")
	$(Q)$(MAKE) post-task SUCCESS_MESSAGE="$(SUCCESS_MESSAGE)"

.PHONY: post-reconfigure-task
post-reconfigure-task:
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

.PHONY: ensure-databases-setup
ensure-databases-setup: Procfile postgresql/data redis/redis.conf ensure-databases-running

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
gdk-reconfigure-task: touch-examples
	@echo
	@echo "${DIVIDER}"
	@echo "Ensuring GDK managed configuration files are up-to-date"
	@echo "${DIVIDER}"
	$(Q)rake reconfigure

# Cleanup the recently no-longer used .gdk-install-root file
.PHONY: clean-gdk-root
clean-gdk-root:
	@rm -f .gdk-install-root
install update all reconfigure: clean-gdk-root
