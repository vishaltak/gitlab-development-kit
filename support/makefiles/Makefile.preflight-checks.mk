.PHONY: preflight-checks
preflight-checks: rake
	@echo
	@echo "${DIVIDER}"
	@echo "GDK: Running preflight checks"
	@echo "${DIVIDER}"
	$(Q)rake preflight-checks

.PHONY: preflight-update-checks
preflight-update-checks: rake
	@echo
	@echo "${DIVIDER}"
	@echo "GDK: Running preflight update checks"
	@echo "${DIVIDER}"
	$(Q)rake preflight-update-checks
