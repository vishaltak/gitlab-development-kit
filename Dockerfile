FROM ubuntu:18.04 AS base
LABEL authors.maintainer "GDK contributors: https://gitlab.com/gitlab-org/gitlab-development-kit/graphs/master"

# Directions when writing this dockerfile:
# Keep least changed directives first. This improves layers caching when rebuilding.

RUN useradd --user-group --create-home gdk
ENV DEBIAN_FRONTEND=noninteractive

# Install packages
COPY packages.txt /
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository ppa:git-core/ppa -y \
    && apt-get install -y $(sed -e 's/#.*//' /packages.txt)

# Install minio
RUN curl https://dl.min.io/server/minio/release/linux-amd64/minio > /usr/local/bin/minio \
  && chmod +x /usr/local/bin/minio

# stages for fetching remote content
# highly cacheable
FROM alpine AS fetch
RUN apk add --no-cache coreutils curl tar git

FROM fetch AS source-rbenv
ARG RBENV_REVISION=v1.1.1
RUN git clone --branch $RBENV_REVISION --depth 1 https://github.com/rbenv/rbenv

FROM fetch AS source-ruby-build
ARG RUBY_BUILD_REVISION=v20191225
RUN git clone --branch $RUBY_BUILD_REVISION --depth 1 https://github.com/rbenv/ruby-build

FROM fetch AS go
ARG GO_SHA256=2f49eb17ce8b48c680cdb166ffd7389702c0dec6effa090c324804a5cac8a7f8
ARG GO_VERSION=1.14.1
RUN curl --silent --location --output go.tar.gz https://dl.google.com/go/go$GO_VERSION.linux-amd64.tar.gz
RUN echo "$GO_SHA256  go.tar.gz" | sha256sum -c -
RUN tar -C /usr/local -xzf go.tar.gz

FROM node:12-stretch AS nodejs
# contains nodejs and yarn in /usr/local
# https://github.com/nodejs/docker-node/blob/77f1baaa55acc71c9eda1866f0c162b434a63be5/10/jessie/Dockerfile
WORKDIR /stage
RUN install -d usr opt
RUN cp -al /usr/local usr
RUN cp -al /opt/yarn* opt

FROM base AS rbenv
WORKDIR /home/gdk
RUN echo 'export PATH="/home/gdk/.rbenv/bin:$PATH"' >> .bash_profile
RUN echo 'eval "$(rbenv init -)"' >> .bash_profile
COPY --from=source-rbenv --chown=gdk /rbenv .rbenv
COPY --from=source-ruby-build --chown=gdk /ruby-build .rbenv/plugins/ruby-build
USER gdk
RUN bash -l -c "rbenv install 2.6.5 && rbenv global 2.6.5"

# build final image
FROM base AS release

WORKDIR /home/gdk
ENV PATH $PATH:/usr/local/go/bin

COPY --from=go /usr/local/ /usr/local/
COPY --from=nodejs /stage/ /
COPY --from=rbenv --chown=gdk /home/gdk/ .

USER gdk

# simple tests that tools work
RUN ["bash", "-lec", "yarn --version; node --version; rbenv --version" ]
