FROM gitpod/workspace-full

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

# scrips/lint-doc.sh dependency
RUN brew install vale

RUN rm -f ~/.rvmrc

RUN bash -lc ' \
        GOPATH=$HOME/go-packages && \
        GOROOT=$HOME/go && \
        gem install gitlab-development-kit rake mdl && \
        cd $HOME && gdk init && \
        npm upgrade --global yarn && \
        export BUNDLER_VERSION="$(grep -A 1 "BUNDLED WITH" "$HOME/gitlab-development-kit/Gemfile.lock" | tail -n 1)" && \
        gem install bundler -v $BUNDLER_VERSION && \
        export RUBY_VERSION=$(awk "\$1 == \"ruby\" {print \$2}" "$HOME/gitlab-development-kit/.tool-versions") && \
        rvm install $RUBY_VERSION --create && \
        rvm use $RUBY_VERSION --default && \
        echo "rvm use $RUBY_VERSION --default > /dev/null" > ~/.bashrc.d/71-ruby && \
        export NODE_VERSION=$(awk "\$1 == \"nodejs\" {print \$2}" "$HOME/gitlab-development-kit/.tool-versions") && \
        . $HOME/.nvm/nvm.sh && \
        nvm install $NODE_VERSION && \
        nvm alias default $NODE_VERSION && \
        export GO_VERSION=$(awk "\$1 == \"golang\" {print \$2}" "$HOME/gitlab-development-kit/.tool-versions") && \
        rm -rf go && curl -sSL https://storage.googleapis.com/golang/go$GO_VERSION.linux-amd64.tar.gz | tar xzs && \
        cd gitlab-development-kit && gdk install shallow_clone=true && \
        gdk stop && \
        rm -rf gitlab && rm -rf tmp && \
        cp ./support/completions/gdk.bash $HOME/.bashrc.d/90-gdk && \
        cd /workspace && mv gitlab-development-kit $HOME/ && mv .rvm $HOME/.rvm-workspace \
    '

RUN echo "rvm_gems_path=/workspace/.rvm\nrvm_silence_path_mismatch_check_flag=1" >> ~/.rvmrc
