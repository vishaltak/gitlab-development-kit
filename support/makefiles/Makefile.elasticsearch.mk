ifeq ($(elasticsearch_enabled),true)
elasticsearch-setup: elasticsearch/bin/elasticsearch
else
elasticsearch-setup:
	@true
endif

elasticsearch/bin/elasticsearch: .cache/.elasticsearch_${elasticsearch_version}_installed

.cache/.elasticsearch_${elasticsearch_version}_installed:
	$(Q)rm -rf elasticsearch && mkdir -p elasticsearch
	$(Q)curl -C - -L --fail "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${elasticsearch_version}-${platform}-x86_64.tar.gz" | tar xzf - --strip-components=1 -C elasticsearch
	$(Q)mkdir -p .cache && touch $@
