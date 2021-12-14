ifeq ($(snowplow_micro_enabled),true)
snowplow-micro-setup: snowplow/snowplow_micro.conf snowplow/iglu.json
else
snowplow-micro-setup:
	@true
endif

.PHONY: snowplow/snowplow_micro.conf
snowplow/snowplow_micro.conf:
	$(Q)rake $@

.PHONY: snowplow/iglu.json
snowplow/iglu.json:
	$(Q)rake $@
