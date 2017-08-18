FROM ruby:slim-stretch
LABEL authors.maintainer hrvoje.marjanovic@gmail.com
LABEL authors.contributor "Matija Cupic <matija@gitlab.com>"

RUN apt-get update && apt-get install -y curl gnupg2 apt-transport-https

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update
# build basics
RUN apt-get install -y git linux-headers-amd64 build-essential cmake pkg-config
# build dependencies
RUN apt-get install -y libicu-dev libre2-dev libkrb5-dev postgresql-server-dev-all libsqlite3-dev
# runtime dependencies
RUN apt-get install -y postgresql-client nodejs yarn golang-1.8
ENV PATH="$PATH:/usr/lib/go-1.8/bin/"
RUN ln -s `which nodejs` /usr/local/bin/node
RUN apt-get install -y bash sudo openssh-client tzdata

RUN useradd --groups sudo --uid 1000 --shell /bin/bash --create-home --user-group gdk
RUN echo "gdk ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/gdk

USER gdk

RUN gem install gitlab-development-kit

COPY . /home/gdk/gitlab-development-kit
RUN sudo chown gdk:gdk -R /home/gdk/gitlab-development-kit
RUN echo "/home/gdk/gitlab-development-kit" > /home/gdk/gitlab-development-kit/.gdk-install-root
RUN gdk trust /home/gdk/gitlab-development-kit

ENV GDK_DOCKER_COMPOSE true

WORKDIR /home/gdk/gitlab-development-kit

COPY compose-entrypoint.sh .
RUN sudo chown gdk:gdk compose-entrypoint.sh
ENTRYPOINT ["./compose-entrypoint.sh"]
