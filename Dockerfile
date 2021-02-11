FROM ubuntu:20.04
LABEL authors.maintainer "GDK contributors: https://gitlab.com/gitlab-org/gitlab-development-kit/-/graphs/main"

# Directions when writing this dockerfile:
# Keep least changed directives first. This improves layers caching when rebuilding.

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y sudo make software-properties-common \
    && add-apt-repository ppa:git-core/ppa -y \
    && apt-get purge software-properties-common -y \
    && apt-get autoremove -y \
    && rm -rf /tmp/*

RUN useradd --user-group --create-home --groups sudo gdk
RUN echo "gdk ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/gdk_no_password

USER gdk
WORKDIR /home/gdk/gitlab-development-kit
COPY --chown=gdk . .

ENV PATH="/home/gdk/.asdf/shims:/home/gdk/.asdf/bin:${PATH}"

RUN make bootstrap \
  # simple tests that tools work
  && bash -lec "asdf version; yarn --version; node --version; ruby --version" \
  # clear tmp caches e.g. from postgres compilation
  && rm -rf /tmp/* ~/.asdf/tmp/*
