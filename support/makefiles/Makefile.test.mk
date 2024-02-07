LYCHEE := $(shell command -v lychee 2> /dev/null)
MARKDOWNLINT := $(shell command -v markdownlint-cli2 2> /dev/null)

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
	@echo -n "Markdownlint: "
	@${YARN} run --silent markdownlint && echo "OK"

# Doesn't check external links
.PHONY: check-links
check-links:
ifeq (${LYCHEE},)
	@echo "ERROR: Lychee not installed. For installation information, see: https://lychee.cli.rs/installation/"
else
	@echo -n "Check internal links: "
	@lychee --version
	@lychee --offline --include-fragments README.md doc/* && echo "OK"
endif

# Usage: make check-duplicates command="gdk update"
.PHONY: check-duplicates
check-duplicates:
	@echo "Checking for duplicated tasks:"
	@ruby ./support/compare.rb "$(command)"

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
