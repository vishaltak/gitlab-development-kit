.PHONY: zoekt-setup
ifeq ($(zoekt_enabled),true)
zoekt-setup: zoekt/bin/zoekt-git-clone zoekt/bin/zoekt-git-index zoekt/bin/zoekt-dynamic-indexserver zoekt/bin/zoekt-webserver
else
zoekt-setup:
	@true
endif

.PHONY: zoekt-update
ifeq ($(zoekt_enabled),true)
zoekt-update: zoekt-update-timed
else
zoekt-update:
	@true
endif

.PHONY: zoekt-update-run
zoekt-update-run: zoekt/.git/pull zoekt-clean-bin zoekt/bin/zoekt-git-clone zoekt/bin/zoekt-git-index zoekt/bin/zoekt-dynamic-indexserver zoekt/bin/zoekt-webserver

zoekt/.git:
	$(Q)GIT_REVISION="${zoekt_version}" CLONE_DIR=zoekt support/component-git-clone ${git_depth_param} ${zoekt_repo} zoekt

zoekt/bin/%: zoekt/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Building $@ version ${zoekt_version}"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec zoekt go build -o bin/$(notdir $@) cmd/$(notdir $@)/main.go

.PHONY: zoekt-clean-bin
zoekt-clean-bin:
	$(Q)rm -rf zoekt/bin

.PHONY: zoekt/.git/pull
zoekt/.git/pull: zoekt/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/zoekt"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update zoekt zoekt "${zoekt_version}" main
