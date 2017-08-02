FROM gdk-base
LABEL authors.maintainer hrvoje.marjanovic@gmail.com
LABEL authors.contributor "Matija Cupic <matija@gitlab.com>"

RUN apk update
# build basics
RUN apk add --no-cache git linux-headers build-base cmake pkgconfig
# build dependencies
RUN apk add --no-cache icu-dev libc6-compat libre2-dev krb5-dev postgresql-dev sqlite-dev
# runtime dependencies
RUN apk add --no-cache postgresql-client nodejs yarn go
# misc
RUN apk add --no-cache bash sudo openssh-client openssh-keygen tzdata

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
	    sed -i 's/s.version     = "3.3.2"/s.version     = "3.3.0"/' google-protobuf.gemspec && \
	    sed -i '12 i\
	    	s.platform       = "x86_64-linux"' google-protobuf.gemspec && \
	    sudo -u gdk bundle && rake && \
	    rake clobber_package gem && \
	    sudo -u gdk gem install --install-dir $GEM_HOME `ls pkg/google-protobuf-*.gem`
RUN apk del curl autoconf automake libtool && rm -rf ./protobuf

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
