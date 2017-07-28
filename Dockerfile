FROM gdk-base
LABEL authors.maintainer hrvoje.marjanovic@gmail.com
LABEL authors.contributor "Matija Cupic <matija@gitlab.com>"

# rest of gitlab requirements

# sudo nodejs npm
# libpq-dev ed pkg-config

RUN apk add --no-cache bash git make build-base krb5-dev icu-dev cmake linux-headers
RUN apk add --no-cache sudo nodejs go
RUN apk add --no-cache mariadb-dev postgresql-dev
RUN apk add --no-cache tzdata
RUN gem install gitlab-development-kit

RUN adduser -D -g sudo -u 1000 gdk
RUN echo "gdk ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/gdk
USER gdk

ENV BUNDLE_PATH="/home/gdk/gitlab-development-kit/.bundle"
ENV GDK_DOCKER_COMPOSE=true

WORKDIR /home/gdk/
RUN gdk init
WORKDIR /home/gdk/gitlab-development-kit
RUN gdk install
