registry-setup: registry/storage registry/config.yml localhost.crt

localhost.crt: localhost.key

localhost.key:
	$(Q)${OPENSSL} req -new -subj "/CN=${hostname}/" -x509 -days 365 -newkey rsa:2048 -nodes -keyout "localhost.key" -out "localhost.crt" -addext "subjectAltName=DNS:${hostname}"
	$(Q)chmod 600 $@

registry_host.crt: registry_host.key

registry_host.key:
	$(Q)${OPENSSL} req -new -subj "/CN=${registry_host}/" -x509 -days 365 -newkey rsa:2048 -nodes -keyout "registry_host.key" -out "registry_host.crt" -addext "subjectAltName=DNS:${registry_host}"
	$(Q)chmod 600 $@

registry/storage:
	$(Q)mkdir -p $@

.PHONY: trust-docker-registry
trust-docker-registry: registry_host.crt
	$(Q)mkdir -p "${HOME}/.docker/certs.d/${registry_host}:${registry_port}"
	$(Q)rm -f "${HOME}/.docker/certs.d/${registry_host}:${registry_port}/ca.crt"
	$(Q)cp registry_host.crt "${HOME}/.docker/certs.d/${registry_host}:${registry_port}/ca.crt"
	$(Q)echo "Certificates have been copied to ~/.docker/certs.d/"
	$(Q)echo "Don't forget to restart Docker!"
