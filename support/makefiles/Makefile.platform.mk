.PHONY: platform-update
platform-update: platform-update-timed

.PHONY: platform-update-run
platform-update-run:
	@support/platform-update
