openssh-setup: openssh/sshd_config openssh/ssh_host_rsa_key

openssh/ssh_host_rsa_key:
	$(Q)ssh-keygen -f $@ -N '' -t rsa

.PHONY: openssh/sshd_config
openssh/sshd_config:
	$(Q)rake $@
