FROM ubuntu:20.04
LABEL authors.maintainer "GDK contributors: https://gitlab.com/gitlab-org/gitlab-development-kit/graphs/master"

# Directions when writing this dockerfile:
# Keep least changed directives first. This improves layers caching when rebuilding.

RUN useradd --user-group --create-home gdk
ENV DEBIAN_FRONTEND=noninteractive

# Install packages
COPY packages.txt /
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository ppa:git-core/ppa -y \
    && apt-get install -y $(sed -e 's/#.*//' /packages.txt) \
    && apt-get purge software-properties-common -y \
    && apt-get autoremove -y \
    && rm -rf /tmp/*

WORKDIR /home/gdk
USER gdk

# Install asdf, plugins and correct versions
ENV PATH="/home/gdk/.asdf/shims:/home/gdk/.asdf/bin:${PATH}"
COPY --chown=gdk .tool-versions .
RUN git clone https://github.com/asdf-vm/asdf.git /home/gdk/.asdf --branch v0.8.0-rc1 && \
  for plugin in $(cat .tool-versions | cut -f1 -d" "); do \
  echo "Installing asdf plugin '$plugin' and install current version" ; \
  asdf plugin add $plugin; \
  NODEJS_CHECK_SIGNATURES=no asdf install ; done \
  && gem install bundler -v '= 1.17.3' \
  # simple tests that tools work
  && bash -lec "asdf version; yarn --version; node --version; ruby --version" \
  # clear tmp caches e.g. from postgres compilation
  && rm -rf /tmp/*
