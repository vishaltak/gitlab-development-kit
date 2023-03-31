.PHONY: openssh-setup
openssh-setup: _gdk-clear-needed-configs _openssh-configs _openssh-setup _gdk-update-needed-configs

.PHONY: _openssh-configs
_openssh-configs:
	${Q}touch support/templates/openssh/sshd_config.erb
	${Q}echo "openssh/sshd_config" >> tmp/.gdk-configs-to-update

.PHONY: _openssh-setup
_openssh-setup: $(sshd_hostkeys)

$(gdk_root)/openssh/ssh_host_%_key:
	$(Q)ssh-keygen -f $@ -N '' -t $*
