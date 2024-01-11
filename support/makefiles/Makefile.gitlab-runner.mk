runner_url = https://gitlab.com/gitlab-org/gitlab-runner
runner_tool_versions_file = ${runner_url}/-/raw/main/.tool-versions

runner-setup: runner-asdf-install gitlab-runner-config.toml

runner-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${runner_tool_versions_file}"
	@echo "${DIVIDER}"
	$(Q)curl --silent ${runner_tool_versions_file} > .tool-versions-runner
	$(Q)ASDF_DEFAULT_TOOL_VERSIONS_FILENAME=".tool-versions-runner" asdf install
	$(Q)asdf reshim
	$(Q)rm -rf .tool-versions-runner
else
	@true
endif
