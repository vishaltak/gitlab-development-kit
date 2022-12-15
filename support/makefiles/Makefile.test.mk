MARKDOWNLINT := $(shell command -v markdownlint 2> /dev/null)

dev_checkmake_binary := $(or $(dev_checkmake_binary),$(shell command -v checkmake 2> /dev/null))

.PHONY: test
test: gdk_bundle_install
	@${support_bundle_exec} lefthook run pre-push

.PHONY: gdk_bundle_install
gdk_bundle_install:
	${Q}$(support_bundle_install) $(gitlab_development_root)

.PHONY: rubocop
ifeq ($(BUNDLE),)
rubocop:
	@echo "ERROR: Bundler is not installed, please ensure you've bootstrapped your machine. See https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/index.md for more details"
	@false
else
rubocop: gdk_bundle_install
	@echo -n "RuboCop: "
	@${support_bundle_exec} $@ --config .rubocop-gdk.yml --parallel
endif

.PHONY: rspec
ifeq ($(BUNDLE),)
rspec:
	@echo "ERROR: Bundler is not installed, please ensure you've bootstrapped your machine. See https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/index.md for more details"
	@false
else
rspec: gdk_bundle_install
	@echo -n "RSpec: "
	@${support_bundle_exec} $@ ${RSPEC_ARGS}
endif

.PHONY: lint
lint: vale markdownlint check-links

.PHONY: vale
vale:
	@support/dev/vale

.PHONY: yarn-install
yarn-install:
ifeq ($(YARN)),)
	@echo "ERROR: YARN is not installed, please ensure you've bootstrapped your machine. See https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/index.md for more details"
	@false
else
	@[[ "${YARN}" ]] && ${YARN} install --silent --frozen-lockfile ${QQ}
endif

.PHONY: markdownlint
markdownlint: yarn-install
	@echo -n "MarkdownLint: "
	@${YARN} run --silent markdownlint-cli2-config .markdownlint.yml 'doc/**/*.md' 'README.md' && echo "OK"

# Checks:
#   - Internal links.
#   - Anchors within the same page.
#
# Doesn't check:
#    - External links.
#    - Anchors on other pages.
.PHONY: check-links
check-links: yarn-install
	@echo -n "Check internal links: "
	@${YARN} run --silent check-links 2>&1 && echo "OK"

.PHONY: shellcheck
shellcheck:
	@support/dev/shellcheck

.PHONY: checkmake
checkmake: ${dev_checkmake_binary}
	@echo -n "Checkmake:   "
	@cat Makefile support/makefiles/*.mk > tmp/.makefile_combined
	@${dev_checkmake_binary} tmp/.makefile_combined && echo -e "\b\bOK"
	@rm -f tmp/.makefile_combined

${dev_checkmake_binary}:
	@support/dev/checkmake-install

.PHONY: verify-gdk-example-yml
verify-gdk-example-yml:
	@echo -n "Checking gdk.example.yml: "
	@support/ci/verify-gdk-example-yml && echo "OK"

.PHONY: verify-asdf-combine
verify-asdf-combine:
	@echo -n "Checking if .tool-versions is up-to-date: "
	@support/ci/verify-asdf-combine && echo "OK"

.PHONY: verify-makefile-config
verify-makefile-config:
	@echo -n "Checking if support/makefiles/Makefile.config.mk is up-to-date: "
	@support/ci/verify-makefile-config && echo "OK"
