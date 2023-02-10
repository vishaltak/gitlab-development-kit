zoekt/.git:
	$(Q)GIT_REVISION="${zoekt_version}" CLONE_DIR=zoekt support/component-git-clone ${git_depth_param} ${zoekt_repo} zoekt

zoekt/bin/%: zoekt/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Building $@ version ${zoekt_version}"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec zoekt go build -o bin/$(notdir $@) cmd/$(notdir $@)/main.go

ifeq ($(zoekt_enabled),true)
zoekt-setup: zoekt/bin/zoekt-git-clone zoekt/bin/zoekt-git-index zoekt/bin/zoekt-dynamic-indexserver zoekt/bin/zoekt-webserver
else
zoekt-setup:
	@true
endif
