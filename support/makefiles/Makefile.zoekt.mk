zoekt/.git:
	$(Q)GIT_REVISION="${zoekt_version}" CLONE_DIR=zoekt support/component-git-clone ${git_depth_param} ${zoekt_repo} zoekt

zoekt/bin/zoekt-git-clone: zoekt/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Building $@ version ${zoekt_version}"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec zoekt go build -o bin/zoekt-git-clone cmd/zoekt-git-clone/main.go

zoekt/bin/zoekt-git-index: zoekt/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Building $@ version ${zoekt_version}"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec zoekt go build -o bin/zoekt-git-index cmd/zoekt-git-index/main.go

zoekt/bin/zoekt-dynamic-indexserver: zoekt/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Building $@ version ${zoekt_version}"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec zoekt go build -o bin/zoekt-dynamic-indexserver cmd/zoekt-dynamic-indexserver/main.go

zoekt/bin/zoekt-webserver: zoekt/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Building $@ version ${zoekt_version}"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec zoekt go build -o bin/zoekt-webserver cmd/zoekt-webserver/main.go

ifeq ($(zoekt_enabled),true)
zoekt-setup: zoekt/bin/zoekt-git-clone zoekt/bin/zoekt-git-index zoekt/bin/zoekt-dynamic-indexserver zoekt/bin/zoekt-webserver
else
zoekt-setup:
	@true
endif
