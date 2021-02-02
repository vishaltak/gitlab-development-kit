# Details from https://grafana.com/grafana/download
GRAFANA_INSTALL = true
GRAFANA_VERSION = 7.3.7
GRAFANA_MACOS_SHA256 = ff1fca8b139141d8ed907ac155ee457552a9076d1c68e6310e48118f9b465f18
GRAFANA_LINUX_SHA256 = f761a69dbd79744bf0557252d7163b9f42ea24c050206a3995a9bd27d54b5914

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

.PHONY:	clean
clean:
	@rm -rf grafana grafana-dashboards grafana-${GRAFANA_VERSION}.${OS}-amd64.tar.gz
