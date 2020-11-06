FROM ubuntu:focal
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install krb5-kdc krb5-admin-server -y

COPY krb5.conf /etc/krb5.conf
COPY krb5kdc/kdc.conf /etc/krb5kdc/kdc.conf
COPY krb5kdc/kadm5.acl /etc/krb5kdc/kadm5.acl

RUN kdb5_util -P password -r EXAMPLE.COM create -s
RUN kadmin.local -q 'addprinc root/admin'
RUN kadmin.local -q 'addprinc -randkey kadmin/krb5.example.com'
RUN kadmin.local -q 'ktadd kadmin/krb5.example.com'
RUN kadmin.local -q 'addprinc -randkey HTTP/gitlab.example.com'
RUN kadmin.local -q 'ktadd -k /etc/http.keytab HTTP/gitlab.example.com'

CMD /usr/sbin/krb5kdc -n && /usr/sbin/kadmind -nofork
