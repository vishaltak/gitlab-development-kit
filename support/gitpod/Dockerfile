FROM gitpod/workspace-full

ARG GITLAB_BUNDLER_VERSION
ARG GITLAB_RUBY_VERSION
ARG GITLAB_NODE_VERSION
ARG GITLAB_GO_VERSION

ENV GO_VERSION=${GITLAB_GO_VERSION} \
    NODE_VERSION=${GITLAB_NODE_VERSION}

RUN sudo apt-get update \
    && sudo apt-get install -y \
        software-properties-common \
        postgresql \
        postgresql-contrib \
        libpq-dev \
        redis-server \
        libicu-dev \
        cmake \
        g++ \
        libre2-dev \
        libkrb5-dev \
        libsqlite3-dev \
        ed \
        pkg-config \
        graphicsmagick \
        runit \
        libimage-exiftool-perl \
        rsync \
        libssl-dev \
    && sudo apt-get clean \
    && sudo rm -rf /var/cache/apt/* /var/lib/apt/lists/* /tmp/*

RUN sudo curl https://dl.min.io/server/minio/release/linux-amd64/minio --output /usr/local/bin/minio && \
    sudo chmod +x /usr/local/bin/minio

RUN curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash

RUN export GITLAB_RUNNER_DISABLE_SKEL=true; sudo -E apt-get install gitlab-runner

# scrips/lint-doc.sh dependency
RUN brew install vale

RUN echo "rvm_silence_path_mismatch_check_flag=1" >> $HOME/.rvmrc

RUN sudo mkdir -p /workspace/gitlab && sudo chown -R gitpod:gitpod /workspace

RUN echo "GITLAB_BUNDLER_VERSION  $GITLAB_BUNDLER_VERSION" && \
    echo "GITLAB_RUBY_VERSION     $GITLAB_RUBY_VERSION" && \
    echo "GITLAB_NODE_VERSION     $GITLAB_NODE_VERSION" && \
    echo "GITLAB_GO_VERSION       $GITLAB_GO_VERSION" && \
    bash -lc " \
        GOPATH=$HOME/go-packages && \
        GOROOT=$HOME/go && \
        npm upgrade --global yarn && \
        rvm install $GITLAB_RUBY_VERSION --create && \
        rvm use $GITLAB_RUBY_VERSION --default && \
        echo \"rvm use $GITLAB_RUBY_VERSION --default > /dev/null\" > ~/.bashrc.d/71-ruby && \
        gem install bundler -v $GITLAB_BUNDLER_VERSION && \
        gem install gitlab-development-kit rake mdl && \
        . $HOME/.nvm/nvm.sh && \
        nvm install $GITLAB_NODE_VERSION && \
        nvm alias default $GITLAB_NODE_VERSION && \
        rm -rf go && curl -sSL https://storage.googleapis.com/golang/go$GITLAB_GO_VERSION.linux-amd64.tar.gz | tar xzs && \
        cd /workspace && gdk init && \
        cd gitlab-development-kit && gdk install shallow_clone=true && \
        gdk stop && \
        rm -rf gitlab && rm -rf tmp && \
        cp ./support/completions/gdk.bash $HOME/.bashrc.d/90-gdk && \
        cd /workspace && mv gitlab-development-kit $HOME/ && mv .rvm $HOME/.rvm-workspace \
    "

RUN sudo rm -rf /workspace

COPY 91-rails-hosts /home/gitpod/.bashrc.d/
COPY startup-scripts /home/gitpod/
