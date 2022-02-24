gitlab_docs_clone_dir = gitlab-docs
gitlab_runner_clone_dir = gitlab-runner
omnibus_gitlab_clone_dir = omnibus-gitlab
charts_gitlab_clone_dir = charts-gitlab
nanoc_cmd = ${BUNDLE} exec nanoc

ifeq ($(gitlab_docs_enabled),true)
gitlab-docs-setup: gitlab-docs/.git gitlab-runner omnibus-gitlab charts-gitlab gitlab-docs-deps
else
gitlab-docs-setup:
	@true
endif

ifeq ($(gitlab_runner_enabled),true)
gitlab-runner: gitlab-runner/.git
else
gitlab-runner:
	@true
endif

ifeq ($(gitlab_runner_enabled),true)
gitlab-runner-pull: gitlab-runner/.git/pull
else
gitlab-runner-pull:
	@true
endif

ifeq ($(omnibus_gitlab_enabled),true)
omnibus-gitlab: omnibus-gitlab/.git
else
omnibus-gitlab:
	@true
endif

ifeq ($(omnibus_gitlab_enabled),true)
omnibus-gitlab-pull: omnibus-gitlab/.git/pull
else
omnibus-gitlab-pull:
	@true
endif

ifeq ($(charts_gitlab_enabled),true)
charts-gitlab: charts-gitlab/.git
else
charts-gitlab:
	@true
endif

ifeq ($(charts_gitlab_enabled),true)
charts-gitlab-pull: charts-gitlab/.git/pull
else
charts-gitlab-pull:
	@true
endif

gitlab-docs/.git:
	$(Q)support/component-git-clone ${git_depth_param} ${gitlab_docs_repo} gitlab-docs

gitlab-docs/.git/pull: gitlab-docs/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-docs"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab_docs "${gitlab_docs_clone_dir}" main main

gitlab-runner/.git:
	$(Q)support/component-git-clone ${git_depth_param} ${gitlab_runner_repo} gitlab-runner

gitlab-runner/.git/pull: gitlab-runner/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-runner"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab_runner "${gitlab_runner_clone_dir}" main main

omnibus-gitlab/.git:
	$(Q)support/component-git-clone ${git_depth_param} ${omnibus_gitlab_repo} omnibus-gitlab

omnibus-gitlab/.git/pull: omnibus-gitlab/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/omnibus-gitlab"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update omnibus_gitlab "${omnibus_gitlab_clone_dir}" master master

charts-gitlab/.git:
	$(Q)support/component-git-clone ${git_depth_param} ${charts_gitlab_repo} charts-gitlab

charts-gitlab/.git/pull: charts-gitlab/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/charts/gitlab"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update charts_gitlab "${charts_gitlab_clone_dir}" master master

.PHONY: gitlab-docs-deps
gitlab-docs-deps: gitlab-docs-bundle gitlab-docs-yarn rm-symlink-gitlab-docs

gitlab-docs-bundle:
	@echo
	@echo "${DIVIDER}"
	@echo "Installing gitlab-org/gitlab-docs Ruby gems"
	@echo "${DIVIDER}"
	${Q}$(support_bundle_install) $(gitlab_development_root)/$(gitlab_docs_clone_dir)

gitlab-docs-yarn:
	$(Q)cd ${gitlab_development_root}/gitlab-docs && ${YARN} install --frozen-lockfile

# Ensure no legacy symlinks are in place
rm-symlink-gitlab-docs:
	$(Q)rm -f ${gitlab_development_root}/${gitlab_docs_clone_dir}/content/ee
	$(Q)rm -f ${gitlab_development_root}/${gitlab_docs_clone_dir}/content/runner
	$(Q)rm -f ${gitlab_development_root}/${gitlab_docs_clone_dir}/content/omnibus
	$(Q)rm -f ${gitlab_development_root}/${gitlab_docs_clone_dir}/content/charts

gitlab-docs-clean:
	$(Q)cd ${gitlab_development_root}/gitlab-docs && rm -rf tmp

gitlab-docs-build:
	$(Q)cd ${gitlab_development_root}/gitlab-docs && $(nanoc_cmd)

.PHONY: gitlab-docs-update
ifeq ($(gitlab_docs_enabled),true)
gitlab-docs-update: gitlab-docs-update-timed
else
gitlab-docs-update:
	@true
endif

.PHONY: gitlab-docs-update-run
gitlab-docs-update-run: gitlab-docs/.git/pull gitlab-runner-pull omnibus-gitlab-pull charts-gitlab-pull gitlab-docs-deps gitlab-docs-build

# Internal links and anchors checks for documentation
ifeq ($(gitlab_docs_enabled),true)
gitlab-docs-check: gitlab-runner-docs-check omnibus-gitlab-docs-check charts-gitlab-docs-check gitlab-docs-build
	$(Q)cd ${gitlab_development_root}/gitlab-docs && \
		$(nanoc_cmd) check internal_links && \
		$(nanoc_cmd) check internal_anchors
else
gitlab-docs-check:
	@echo "ERROR: gitlab_docs is not enabled. See doc/howto/gitlab_docs.md"
	@false
endif

ifneq ($(gitlab_runner_enabled),true)
gitlab-runner-docs-check:
	@echo "ERROR: gitlab_runner is not enabled. See doc/howto/gitlab_docs.md"
	@false
else
gitlab-runner-docs-check:
	@true
endif

ifneq ($(omnibus_gitlab_enabled),true)
omnibus-gitlab-docs-check:
	@echo "ERROR: omnibus_gitlab is not enabled. See doc/howto/gitlab_docs.md"
	@false
else
omnibus-gitlab-docs-check:
	@true
endif

ifneq ($(charts_gitlab_enabled),true)
charts-gitlab-docs-check:
	@echo "ERROR: charts_gitlab is not enabled. See doc/howto/gitlab_docs.md"
	@false
else
charts-gitlab-docs-check:
	@true
endif
