# Details from https://grafana.com/grafana/download
GRAFANA_INSTALL = true
GRAFANA_VERSION = 8.1.4
GRAFANA_MACOS_SHA256 = 367a33cc9fea711e96243b43d337d7ae1f086ca7e71bdac4b650df6435e8f6b7
GRAFANA_LINUX_SHA256 = 6b57d8e16f197c0f7049bd4388d8b14e7c0a85fa09fac6a56915dccb5636b7d6

# Determine host operating system
ifeq ($(shell uname -s), Darwin)
	OS = darwin
	GRAFANA_SHA256 = ${GRAFANA_MACOS_SHA256}
else ifeq ($(shell uname -s), Linux)
	OS = linux
	GRAFANA_SHA256 = ${GRAFANA_LINUX_SHA256}
else
	GRAFANA_INSTALL = false
endif

.PHONY: all
all: grafana grafana-dashboards

ifeq ($(GRAFANA_INSTALL),true)
grafana:
	@curl -L --fail https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.${OS}-amd64.tar.gz -o grafana-${GRAFANA_VERSION}.${OS}-amd64.tar.gz
	@echo "${GRAFANA_SHA256}  grafana-${GRAFANA_VERSION}.${OS}-amd64.tar.gz" | shasum -a 256 -c -
	@tar -zxf grafana-${GRAFANA_VERSION}.${OS}-amd64.tar.gz
	@mv grafana-${GRAFANA_VERSION} grafana
else
grafana:
	@echo "ERROR: Unsupported platform."
endif

ifeq ($(GRAFANA_INSTALL),true)
grafana-dashboards:
	@git clone https://gitlab.com/gitlab-org/grafana-dashboards.git
else
grafana-dashboards:
	@echo "ERROR: Unsupported platform."
endif

.PHONY: test
test:
	@true

.PHONY: clean
clean:
	@rm -rf grafana grafana-dashboards grafana-${GRAFANA_VERSION}.${OS}-amd64.tar.gz
