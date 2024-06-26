gitlab_docs_dir = ${gitlab_development_root}/gitlab-docs
gitlab_runner_clone_dir = gitlab-runner
omnibus_gitlab_clone_dir = omnibus-gitlab
charts_gitlab_clone_dir = charts-gitlab
gitlab_operator_clone_dir = gitlab-operator

# Silence Rollup when building GitLab Docs with nanoc
export ROLLUP_OPTIONS = --silent

make_docs = $(Q)make -C ${gitlab_docs_dir}

ifeq ($(gitlab_docs_enabled),true)
gitlab-docs-setup: gitlab-docs/.git gitlab-runner omnibus-gitlab charts-gitlab gitlab-operator gitlab-docs-deps
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

ifeq ($(gitlab_operator_enabled),true)
gitlab-operator: gitlab-operator/.git
else
gitlab-operator:
	@true
endif

ifeq ($(gitlab_operator_enabled),true)
gitlab-operator-pull: gitlab-operator/.git/pull
else
gitlab-operator-pull:
	@true
endif

gitlab-docs/.git:
	$(Q)support/component-git-clone ${git_params} ${gitlab_docs_repo} gitlab-docs

gitlab-docs/.git/pull: gitlab-docs/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-docs"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab_docs "${gitlab_docs_clone_dir}" main main

gitlab-runner/.git:
	$(Q)support/component-git-clone ${git_params} ${gitlab_runner_repo} gitlab-runner

gitlab-runner/.git/pull: gitlab-runner/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-runner"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab_runner "${gitlab_runner_clone_dir}" main main

omnibus-gitlab/.git:
	$(Q)support/component-git-clone ${git_params} ${omnibus_gitlab_repo} omnibus-gitlab

omnibus-gitlab/.git/pull: omnibus-gitlab/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/omnibus-gitlab"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update omnibus_gitlab "${omnibus_gitlab_clone_dir}" master master

charts-gitlab/.git:
	$(Q)support/component-git-clone ${git_params} ${charts_gitlab_repo} charts-gitlab

charts-gitlab/.git/pull: charts-gitlab/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/charts/gitlab"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update charts_gitlab "${charts_gitlab_clone_dir}" master master

gitlab-operator/.git:
	$(Q)support/component-git-clone ${git_params} ${gitlab_operator_repo} gitlab-operator

gitlab-operator/.git/pull: gitlab-operator/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/cloud-native/gitlab-operator"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab_operator "${gitlab_operator_clone_dir}" master master

.PHONY: gitlab-docs-deps
gitlab-docs-deps: gitlab-docs-asdf-install gitlab-docs-bundle gitlab-docs-yarn

gitlab-docs-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${gitlab_docs_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${gitlab_docs_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${gitlab_docs_dir}/.tool-versions" make install-asdf-dependencies
else
	@true
endif

gitlab-docs-bundle:
	@echo
	@echo "${DIVIDER}"
	@echo "Installing gitlab-org/gitlab-docs Ruby gems"
	@echo "${DIVIDER}"
	${Q}$(support_bundle_install) $(gitlab_docs_dir)

gitlab-docs-yarn:
	$(Q)cd ${gitlab_docs_dir} && make install-nodejs-dependencies

gitlab-docs-clean:
	$(Q)cd ${gitlab_docs_dir} && rm -rf tmp

gitlab-docs-build:
	$(make_docs) compile

.PHONY: gitlab-docs-update
ifeq ($(gitlab_docs_enabled),true)
gitlab-docs-update: gitlab-docs-update-timed
else
gitlab-docs-update:
	@true
endif

.PHONY: gitlab-docs-update-run
gitlab-docs-update-run: gitlab-docs/.git/pull gitlab-runner-pull omnibus-gitlab-pull charts-gitlab-pull gitlab-operator-pull gitlab-docs-deps gitlab-docs-build

# Internal links and anchors checks for documentation
ifeq ($(gitlab_docs_enabled),true)
gitlab-docs-check: gitlab-runner-docs-check omnibus-gitlab-docs-check charts-gitlab-docs-check gitlab-operator-docs-check gitlab-docs-build
	$(make_docs) internal-links-and-anchors-check
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

ifneq ($(gitlab_operator_enabled),true)
gitlab-operator-docs-check:
	@echo "ERROR: gitlab_operator is not enabled. See doc/howto/gitlab_docs.md"
	@false
else
gitlab-operator-docs-check:
	@true
endif

