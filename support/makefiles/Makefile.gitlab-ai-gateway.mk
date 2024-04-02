gitlab_ai_gateway_dir = ${gitlab_development_root}/gitlab-ai-gateway

.PHONY: gitlab-ai-gateway-setup
ifeq ($(gitlab_ai_gateway_enabled),true)
gitlab-ai-gateway-setup: gitlab-ai-gateway-setup-timed
else
gitlab-ai-gateway-setup:
	@true
endif

.PHONY: gitlab-ai-gateway-setup-run
gitlab-ai-gateway-setup-run: gitlab-ai-gateway/.git gitlab-ai-common-setup gitlab-ai-gateway-gcloud-setup

.PHONY: gitlab-ai-common-setup
gitlab-ai-common-setup: gitlab-ai-gateway/.env gitlab-ai-gateway-asdf-install gitlab-ai-gateway-poetry-install

gitlab-ai-gateway/.env:
	$(Q)cd ${gitlab_ai_gateway_dir} && cp example.env .env
	$(Q)cd ${gitlab_ai_gateway_dir} && echo -e "\n# GDK additions" >> .env
	$(Q)cd ${gitlab_ai_gateway_dir} && echo "AIGW_VERTEX_TEXT_MODEL__PROJECT=ai-enablement-dev-69497ba7" >> .env

.PHONY: gitlab-ai-gateway-poetry-install
gitlab-ai-gateway-poetry-install:
	@echo
	@echo "${DIVIDER}"
	@echo "Performing poetry steps for ${gitlab_ai_gateway_dir}"
	@echo "${DIVIDER}"
	$(Q)cd ${gitlab_ai_gateway_dir} && poetry install

.PHONY: gitlab-ai-gateway-gcloud-setup
gitlab-ai-gateway-gcloud-setup:
	@echo
	@echo "${DIVIDER}"
	@echo "Logging into Google Cloud for ${gitlab_ai_gateway_dir}"
	@echo "${DIVIDER}"
	$(Q)cd ${gitlab_ai_gateway_dir} && gcloud auth application-default login

.PHONY: gitlab-ai-gateway-update
ifeq ($(gitlab_ai_gateway_enabled),true)
gitlab-ai-gateway-update: gitlab-ai-gateway-update-timed
else
gitlab-ai-gateway-update:
	@true
endif

.PHONY: gitlab-ai-gateway-update-run
gitlab-ai-gateway-update-run: gitlab-ai-gateway/.git/pull gitlab-ai-common-setup

.PHONY: gitlab-ai-gateway-asdf-install
gitlab-ai-gateway-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${gitlab_ai_gateway_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${gitlab_ai_gateway_dir} && egrep -v '^#' .tool-versions | awk '{ print $$1 }' | xargs -L 1 asdf plugin add
	$(Q)cd ${gitlab_ai_gateway_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${gitlab_ai_gateway_dir}/.tool-versions" asdf install
	$(Q)cd ${gitlab_ai_gateway_dir} && asdf reshim
else
	@true
endif

gitlab-ai-gateway/.git:
	$(Q)support/component-git-clone ${git_params} ${gitlab_ai_gateway_repo} gitlab-ai-gateway

.PHONY: gitlab-ai-gateway/.git/pull
gitlab-ai-gateway/.git/pull: gitlab-ai-gateway/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-ai-gateway"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update gitlab_ai_gateway gitlab-ai-gateway main main
