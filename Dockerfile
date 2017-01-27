FROM ubuntu:16.04
MAINTAINER hrvoje.marjanovic@gmail.com

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get -y install curl git-core software-properties-common python-software-properties
# This PPA contains an up-to-date version of Go
RUN apt-add-repository -y ppa:ubuntu-lxc/lxd-stable
RUN apt-get update


# install essentials
RUN apt-get -y install build-essential
RUN apt-get install -y -q git
RUN apt-get install -y libssl-dev

# rest of gitlab requirements
RUN apt-get -y install git postgresql postgresql-contrib libpq-dev redis-server libicu-dev cmake g++ nodejs libkrb5-dev golang ed pkg-config
RUN apt-get install -y libreadline-dev npm sudo

# Install rbenv

RUN adduser --disabled-password --gecos "" gdk

USER gdk
RUN git clone https://github.com/sstephenson/rbenv.git /home/gdk/.rbenv
RUN echo 'export PATH="/home/gdk/.rbenv/bin:$PATH"' >> /home/gdk/.bash_profile
RUN echo 'eval "$(rbenv init -)"' >> /home/gdk/.bash_profile

# install ruby-build
RUN mkdir /home/gdk/.rbenv/plugins
RUN git clone https://github.com/sstephenson/ruby-build.git /home/gdk/.rbenv/plugins/ruby-build
RUN bash -l -c "rbenv install 2.3.3 && rbenv global 2.3.3"

WORKDIR /home/gdk

ENV host=0.0.0.0 port=5000

ADD review-apps/init /review-apps/init
RUN /review-apps/init

USER root
RUN apt-get install -y nano vim ed
USER gdk

ADD review-apps/run /review-apps/run
COPY support /home/gdk/gitlab-development-kit/support
COPY Makefile /home/gdk/gitlab-development-kit/Makefile

EXPOSE 5000
CMD ["/review-apps/run"]
