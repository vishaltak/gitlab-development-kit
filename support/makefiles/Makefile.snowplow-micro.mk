ifeq ($(snowplow_micro_enabled),true)
snowplow-micro-setup: snowplow/snowplow_micro.conf snowplow/iglu.json
else
snowplow-micro-setup:
	@true
endif

snowplow-micro-update: snowplow-micro-setup
