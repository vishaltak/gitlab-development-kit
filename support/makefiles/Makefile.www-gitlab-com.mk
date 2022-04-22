www_gitlab_com_clone_dir = www-gitlab-com

.PHONY: www-gitlab-com-setup
ifeq ($(www_gitlab_com_enabled),true)
www-gitlab-com-setup: www-gitlab-com/.git .www-gitlab-com-yarn
else
www-gitlab-com-setup:
	@true
endif

.PHONY: www-gitlab-com-update
ifeq ($(www_gitlab_com_enabled),true)
www-gitlab-com-update: www-gitlab-com-update-timed
else
www-gitlab-com-update:
	@true
endif

.PHONY: www-gitlab-com-update-run
www-gitlab-com-update-run: www-gitlab-com/.git www-gitlab-com/.git/pull www-gitlab-com-clean .www-gitlab-com-yarn

www-gitlab-com/.git:
	$(Q)support/component-git-clone ${git_depth_param} ${www_gitlab_com_repo} ${www_gitlab_com_clone_dir} ${QQ}

www-gitlab-com/.git/pull:
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-com/www-gitlab-com"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update www_gitlab_com "${www_gitlab_com_clone_dir}" master master

.PHONY: www-gitlab-com-clean
www-gitlab-com-clean:
	@rm -f .www-gitlab-com-yarn

.www-gitlab-com-yarn:
ifeq ($(YARN),)
	@echo "ERROR: YARN is not installed, please ensure you've bootstrapped your machine. See https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/index.md for more details"
	@false
else
	@echo
	@echo "${DIVIDER}"
	@echo "Installing gitlab-com/www-gitlab-com Node.js packages"
	@echo "${DIVIDER}"
	$(Q)cd ${gitlab_development_root}/www-gitlab-com && ${YARN} install --silent
	@echo "${DIVIDER}"
	@echo "Installing gitlab-com/www-gitlab-com Ruby gems"
	@echo "${DIVIDER}"
	$(Q)cd ${gitlab_development_root}/www-gitlab-com && $(support_bundle_install) $(gitlab_development_root)/$(www_gitlab_com_clone_dir)
	@echo "${DIVIDER}"
	@echo "Building gitlab-com/www-gitlab-com"
	$(Q)cd ${gitlab_development_root}/www-gitlab-com && rm -rf public && mkdir -p public
	@echo "${DIVIDER}"
	@echo "INFO: Building team.yml"
	$(Q)cd ${gitlab_development_root}/www-gitlab-com && ${BUNDLE} exec rake build:team_yml ${QQ}
	@echo "INFO: Building images"
	$(Q)cd ${gitlab_development_root}/www-gitlab-com && ${BUNDLE} exec rake build:images ${QQ}
	@echo "INFO: Building webpack assets"
	$(Q)cd ${gitlab_development_root}/www-gitlab-com && ${BUNDLE} exec rake build:packaged_webpack_assets ${QQ}
	@echo "INFO: Building assets"
	$(Q)cd ${gitlab_development_root}/www-gitlab-com && ${BUNDLE} exec rake build:assets ${QQ}
ifeq ($(www_gitlab_com_build_site),handbook)
	@echo "INFO: Building handbook site"
	$(Q)cd ${gitlab_development_root}/www-gitlab-com && ${BUNDLE} exec rake build:handbook ${QQ}
endif
ifeq ($(www_gitlab_com_build_site),uncategorized)
	@echo "INFO: Building uncategorized site"
	$(Q)cd ${gitlab_development_root}/www-gitlab-com && ${BUNDLE} exec rake build:uncategorized ${QQ}
endif
	$(Q)touch $@
endif
