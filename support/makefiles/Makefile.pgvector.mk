.PHONY: pgvector-setup
ifeq ($(pgvector_enabled),true)
pgvector-setup: pgvector/vector.so
else
pgvector-setup:
	@true
endif

.PHONY: pgvector-update
ifeq ($(pgvector_enabled),true)
pgvector-update: pgvector-update-timed
else
pgvector-update:
	@true
endif

.PHONY: pgvector-update-run
pgvector-update-run: pgvector/.git/pull pgvector-clean pgvector/vector.so

pgvector/.git:
	$(Q)GIT_REVISION="${pgvector_version}" CLONE_DIR=pgvector support/component-git-clone ${git_depth_param} ${pgvector_repo} pgvector

pgvector/vector.so: pgvector/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Building $@ version ${pgvector_version}"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec pgvector $(MAKE) ${QQ}
	$(Q)support/asdf-exec pgvector $(MAKE) install ${QQ}

.PHONY: pgvector-clean
pgvector-clean:
	$(Q)support/asdf-exec pgvector $(MAKE) clean ${QQ}

.PHONY: pgvector/.git/pull
pgvector/.git/pull: pgvector/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/pgvector"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update pgvector pgvector "${pgvector_version}" main
