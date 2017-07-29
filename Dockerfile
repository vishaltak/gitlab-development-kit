FROM gdk-base
LABEL authors.maintainer hrvoje.marjanovic@gmail.com
LABEL authors.contributor "Matija Cupic <matija@gitlab.com>"

# rest of gitlab requirements

# sudo nodejs npm
# libpq-dev ed pkg-config

RUN apk update
# build basics
RUN apk add --no-cache bash git linux-headers build-base cmake pkgconfig
# runtime dependencies
RUN apk add --no-cache icu-dev libc6-compat libre2-dev krb5-dev postgresql-dev sqlite-dev
# runtimes
RUN apk add --no-cache nodejs yarn go
# misc
RUN apk add --no-cache sudo tzdata

RUN adduser -D -g sudo -u 1000 gdk
RUN echo "gdk ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/gdk

# workaround for https://github.com/google/protobuf/issues/2335
RUN apk add --no-cache curl autoconf automake libtool
RUN git clone https://github.com/google/protobuf/
RUN cd ./protobuf && \
	    ./autogen.sh && \
	    ./configure --prefix=/usr && \
	    make -j 3 && \
	    make check && \
	    make install
RUN chmod 777 ./protobuf/ruby && cd ./protobuf/ruby && \
	    sed -i 's/s.version     = "3.3.2"/s.version     = "3.2.0.2"/' google-protobuf.gemspec && \
	    sed -i '12 i\
	    	s.platform       = "x86_64-linux"' google-protobuf.gemspec && \
	    sudo -u gdk bundle && rake && \
	    rake clobber_package gem && \
	    sudo -u gdk gem install --install-dir $GEM_HOME `ls pkg/google-protobuf-*.gem`
RUN apk del curl autoconf automake libtool && rm -rf ./protobuf

USER gdk

RUN gem install gitlab-development-kit

ENV GDK_DOCKER_COMPOSE true

RUN gdk init /home/gdk/gitlab-development-kit
WORKDIR /home/gdk/gitlab-development-kit
RUN gem list
RUN gdk install
