.PHONY: preflight-checks
preflight-checks: preflight-checks-timed

.PHONY: preflight-checks-run
preflight-checks-run: rake
	$(Q)rake preflight-checks

.PHONY: preflight-update-checks
preflight-update-checks: preflight-update-checks-timed

.PHONY: preflight-update-checks-run
preflight-update-checks-run: rake
	$(Q)rake preflight-update-checks
