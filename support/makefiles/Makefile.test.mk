MARKDOWNLINT := $(shell command -v markdownlint 2> /dev/null)
RUBOCOP := $(shell command -v rubocop 2> /dev/null)
RSPEC := $(shell command -v rspec 2> /dev/null)

dev_checkmake_binary := $(or $(dev_checkmake_binary),$(shell command -v checkmake 2> /dev/null))
dev_shellcheck_binary := $(or $(dev_shellcheck_binary),$(shell command -v shellcheck 2> /dev/null))
dev_vale_binary := $(or $(dev_vale_binary),$(shell command -v vale 2> /dev/null))

.PHONY: test
test: checkmake lint shellcheck rubocop rspec verify-gdk-example-yml verify-asdf-combine verify-makefile-config

.PHONY: rubocop
rubocop:
ifeq ($(BUNDLE),)
	@echo "ERROR: Bundler is not installed, please ensure you've bootstrapped your machine. See https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/index.md for more details"
	@false
else
ifeq ($(RUBOCOP),)
	@echo "INFO: Installing RuboCop.."
	$(Q)$(gem_install_required_bundler) && ${bundle_install_cmd} ${QQ}
endif
	@echo -n "RuboCop: "
	@${BUNDLE} exec $@ --config .rubocop-gdk.yml --parallel
endif

.PHONY: rspec
rspec:
ifeq ($(BUNDLE),)
	@echo "ERROR: Bundler is not installed, please ensure you've bootstrapped your machine. See https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/index.md for more details"
	@false
else
ifeq ($(RSPEC),)
	@echo "INFO: Installing RSpec.."
	$(Q)$(gem_install_required_bundler) && ${bundle_install_cmd} ${QQ}
endif
	@echo -n "RSpec: "
	@${BUNDLE} exec $@ ${RSPEC_ARGS}
endif

.PHONY: lint
lint: vale markdownlint check-links

$(dev_vale_binary):
	@support/dev/vale-install

.PHONY: vale
vale: $(dev_vale_binary)
	@echo -n "Vale: "
	@${dev_vale_binary} --minAlertLevel error *.md doc README.md

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
	@${YARN} run --silent markdownlint --config .markdownlint.yml 'doc/**/*.md' 'README.md' && echo "OK"

# Checks internal links. Doesn't check external links or anchors.
.PHONY: check-links
check-links: yarn-install
	@echo -n "Check internal links: "
	@${YARN} run --silent check-links 2>&1 && echo "OK"

.PHONY: shellcheck
shellcheck: ${dev_shellcheck_binary}
	@echo -n "Shellcheck: "
	@support/dev/shellcheck && echo "OK"

${dev_shellcheck_binary}:
	@support/dev/shellcheck-install

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
