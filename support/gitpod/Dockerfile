FROM jdkato/vale AS vale-source

FROM gitpod/workspace-base

ARG git_checkout_branch
ENV GIT_CHECKOUT_BRANCH $git_checkout_branch

# Install vale (scripts/lint-doc.sh dependency)
COPY --from=vale-source /bin/vale /usr/bin/vale

# Install gdk and dependencies
COPY bootstrap-gitpod-image.sh /tmp

USER root
RUN chown gitpod /tmp/bootstrap-gitpod-image.sh

USER gitpod
RUN bash /tmp/bootstrap-gitpod-image.sh
RUN rm -rf ${HOME}/gitlab-development-kit/gitlab

# Setup gitpod related startup scripts
USER root

COPY 91-gitlab-env /home/gitpod/.bashrc.d/
RUN chown gitpod /home/gitpod/.bashrc.d/91-gitlab-env
RUN chmod 644 /home/gitpod/.bashrc.d/91-gitlab-env

COPY startup-scripts /home/gitpod/
RUN chown gitpod /home/gitpod/gitpod-*

USER gitpod
