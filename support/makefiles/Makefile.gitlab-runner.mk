runner_url = https://gitlab.com/gitlab-org/gitlab-runner
runner_tool_versions_remote_file = ${runner_url}/-/raw/main/.tool-versions
runner_tool_versions_local_file = tmp/.tool-versions-runner

runner-setup: runner-asdf-install gitlab-runner-config.toml

runner-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${runner_tool_versions_remote_file}"
	@echo "${DIVIDER}"
	$(Q)curl --silent ${runner_tool_versions_remote_file} > ${runner_tool_versions_local_file}
	$(Q)ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${runner_tool_versions_local_file}" asdf install
	$(Q)asdf reshim
else
	@true
endif
