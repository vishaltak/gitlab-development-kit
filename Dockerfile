FROM ruby:2.3-slim
LABEL authors.maintainer hrvoje.marjanovic@gmail.com
LABEL authors.contributor "Matija Cupic <matija@gitlab.com>"

RUN apt-get update && apt-get install -y curl gnupg2 apt-transport-https

RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update
# apt basics
RUN apt-get install -y software-properties-common python-software-properties
# build basics
RUN apt-get install -y git ed wget linux-headers-amd64 build-essential cmake g++ pkg-config
# build dependencies
RUN apt-get install -y libicu-dev libre2-dev libkrb5-dev postgresql-server-dev-all libsqlite3-dev libreadline-dev libssl-dev
# runtime dependencies
RUN apt-get install -y bash sudo postgresql-client openssh-client yarn tzdata
RUN apt-get install -y nodejs && ln -s $(which nodejs) /usr/local/bin/node
RUN curl -O https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.8.3.linux-amd64.tar.gz && rm go1.8.3.linux-amd64.tar.gz
ENV GOROOT /usr/local/go
ENV PATH=$GOROOT/bin:$PATH

RUN useradd --groups sudo --uid 1000 --shell /bin/bash --create-home --user-group gdk
RUN echo "gdk ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/gdk

USER gdk
WORKDIR /home/gdk/

# Gems
RUN curl -OO https://gitlab.com/gitlab-org/gitlab-ce/raw/master/{Gemfile,Gemfile.lock} && bundle install --without mysql production --jobs 4 && rm Gemfile Gemfile.lock
RUN curl -OO https://gitlab.com/gitlab-org/gitlab-shell/raw/master/{Gemfile,Gemfile.lock} && bundle install --without production --jobs 4 && rm Gemfile Gemfile.lock
RUN curl -OO https://gitlab.com/gitlab-org/gitaly/raw/master/ruby/{Gemfile,Gemfile.lock} && bundle install && rm Gemfile Gemfile.lock
RUN curl -OO https://gitlab.com/gitlab-com/gitlab-docs/raw/master/{Gemfile,Gemfile.lock} && bundle install --jobs 4 && rm Gemfile Gemfile.lock

RUN gem install gitlab-development-kit
# RUN gdk init

###
# Needed only while the docker-compose branch isn't merged to master
COPY . /home/gdk/gitlab-development-kit
RUN sudo chown gdk:gdk -R /home/gdk/gitlab-development-kit
RUN echo "/home/gdk/gitlab-development-kit" > /home/gdk/gitlab-development-kit/.gdk-install-root
RUN gdk trust /home/gdk/gitlab-development-kit

ENV GDK_DOCKER_COMPOSE true

WORKDIR /home/gdk/gitlab-development-kit

COPY compose-entrypoint.sh .
RUN sudo chown gdk:gdk compose-entrypoint.sh
###

ENTRYPOINT ["./compose-entrypoint.sh"]
