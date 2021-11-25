openssh-setup: openssh/sshd_config $(sshd_hostkeys)

$(gdk_root)/openssh/ssh_host_%_key:
	$(Q)ssh-keygen -f $@ -N '' -t $*

.PHONY: openssh/sshd_config
openssh/sshd_config:
	$(Q)rake $@
