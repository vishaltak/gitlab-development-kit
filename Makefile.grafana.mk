ifeq ($(grafana_enabled),true)
grafana-setup: grafana/grafana.ini grafana/grafana/bin/grafana-server grafana/gdk-pg-created
else
grafana-setup:
	@true
endif

grafana/grafana/bin/grafana-server:
	$(Q)cd grafana && ${MAKE} ${QQ}

.PHONY: Procfile
grafana/grafana.ini:
	$(Q)rake $@

grafana/gdk-pg-created:
	$(Q)support/create-grafana-db
	$(Q)touch $@

grafana-update:
	@true
