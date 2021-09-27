prom-setup: prometheus/prometheus.yml

.PHONY: prometheus/prometheus.yml
prometheus/prometheus.yml:
	$(Q)rake $@
