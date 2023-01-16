FROM jdkato/vale AS vale-source

FROM gitpod/workspace-base

ARG git_checkout_branch
ENV GIT_CHECKOUT_BRANCH $git_checkout_branch

ARG git_remote_origin_url
ENV GIT_REMOTE_ORIGIN_URL $git_remote_origin_url

# --- Install vale (scripts/lint-doc.sh dependency)
COPY --from=vale-source /bin/vale /usr/bin/vale

# --- USER gitpod
# `gitpod/workspace-base` image sets USER to `gitpod`,
# making commands below run under this user

# --- Install GitLab Runner
# GDK doesn't install it, but it is needed for running pipelines
# https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/runner.md
RUN curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
RUN sudo apt-get install gitlab-runner -y

# --- Install GDK with dependencies
COPY --chown=gitpod bootstrap-gitpod-image.sh /tmp
RUN bash /tmp/bootstrap-gitpod-image.sh
RUN rm -rf ${HOME}/gitlab-development-kit/gitlab

# Setup gitpod related startup scripts
COPY --chown=gitpod 91-gitlab-env /home/gitpod/.bashrc.d/
# these are used in GitLab's `.gitpod.yml`
COPY --chown=gitpod startup-scripts /home/gitpod/
