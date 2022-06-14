FROM jdkato/vale AS vale-source

FROM gitpod/workspace-base

WORKDIR /workspace/gitlab-development-kit

# Install vale (scripts/lint-doc.sh dependency)
COPY --from=vale-source /bin/vale /usr/bin/vale

# Install asdf manifest for `asdf which pg_config` to work in configure_ruby_bundler() function
COPY .tool-versions /workspace/gitlab-development-kit

# Install gdk and dependencies
COPY bootstrap-gitpod-image.sh /
RUN bash /bootstrap-gitpod-image.sh
RUN rm -rf ${HOME}/gitlab-development-kit/gitlab

# Setup gitpod related startup scripts
COPY 91-gitlab-env /home/gitpod/.bashrc.d/
COPY startup-scripts /home/gitpod/
