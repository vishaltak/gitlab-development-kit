gitlab_k8s_agent_clone_dir = gitlab-k8s-agent
gitlab_k8s_agent_version = $(shell support/resolve-dependency-commitish "${gitlab_development_root}/gitlab/GITLAB_KAS_VERSION")

ifeq ($(gitlab_k8s_agent_enabled),true)
gitlab-k8s-agent-setup: gitlab-k8s-agent/build/gdk/bin/kas_race gitlab-k8s-agent-config.yml
else
gitlab-k8s-agent-setup:
	@true
endif

.PHONY: gitlab-k8s-agent-update
ifeq ($(gitlab_k8s_agent_enabled),true)
gitlab-k8s-agent-update: gitlab-k8s-agent-update-timed
else
gitlab-k8s-agent-update:
	@true
endif

.PHONY: gitlab-k8s-agent-update-run
gitlab-k8s-agent-update-run: ${gitlab_k8s_agent_clone_dir}/.git gitlab-k8s-agent/.git/pull gitlab-k8s-agent/build/gdk/bin/kas_race


.PHONY: gitlab-k8s-agent-clean
gitlab-k8s-agent-clean:
	$(Q)rm -rf "${gitlab_k8s_agent_clone_dir}/build/gdk/bin"
	cd "${gitlab_k8s_agent_clone_dir}" && bazel clean

gitlab-k8s-agent/build/gdk/bin/kas_race: ${gitlab_k8s_agent_clone_dir}/.git gitlab-k8s-agent/bazel
	@echo
	@echo "${DIVIDER}"
	@echo "Installing gitlab-org/cluster-integration/gitlab-agent"
	@echo "${DIVIDER}"
	$(Q)mkdir -p "${gitlab_k8s_agent_clone_dir}/build/gdk/bin"
	$(Q)$(MAKE) -C "${gitlab_k8s_agent_clone_dir}" gdk-install TARGET_DIRECTORY="$(CURDIR)/${gitlab_k8s_agent_clone_dir}/build/gdk/bin" ${QQ}

ifeq ($(platform),darwin)
gitlab-k8s-agent/bazel: /usr/local/bin/bazelisk
	$(Q)touch $@
else
.PHONY: gitlab-k8s-agent/bazel
gitlab-k8s-agent/bazel:
	@echo "INFO: To install bazel, please consult the docs at https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/kubernetes_agent.md"
endif

/usr/local/bin/bazelisk:
	$(Q)brew install bazelisk

${gitlab_k8s_agent_clone_dir}/.git:
	$(Q)support/component-git-clone ${git_depth_param} ${gitlab_k8s_agent_repo} ${gitlab_k8s_agent_clone_dir} --revision "${gitlab_k8s_agent_version}" ${QQ}

gitlab-k8s-agent/.git/pull:
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/cluster-integration/gitlab-agent to ${gitlab_k8s_agent_version}"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab_k8s_agent "${gitlab_k8s_agent_clone_dir}" "${gitlab_k8s_agent_version}" master
