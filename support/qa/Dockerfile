ARG release_image
FROM ${release_image}

LABEL authors.maintainer "GDK contributors: https://gitlab.com/gitlab-org/gitlab-development-kit/-/graphs/main"

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

ARG url
ENV URL=${url}
ARG sha
ENV SHA=${sha}

WORKDIR /home/gdk

ENV PATH="/home/gdk/.asdf/shims:/home/gdk/.asdf/bin:${PATH}"

RUN curl --fail "${URL}/-/raw/${SHA}/support/install" | bash -s - gdk "${SHA}"
