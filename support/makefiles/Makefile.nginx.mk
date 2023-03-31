.PHONY: nginx-setup
nginx-setup: _gdk-clear-needed-configs _nginx-configs _nginx-setup _gdk-update-needed-configs

.PHONY: _nginx-configs
_nginx-configs:
	${Q}touch support/templates/nginx/conf/nginx.conf.erb
	${Q}echo "nginx/conf/nginx.conf" >> tmp/.gdk-configs-to-update

.PHONY: _nginx-setup
_nginx-setup: nginx/logs nginx/tmp

nginx/logs:
	$(Q)mkdir -p $@

nginx/tmp:
	$(Q)mkdir -p $@
