FROM jdkato/vale AS vale-source

FROM gitpod/workspace-base

ARG git_checkout_branch
ENV GIT_CHECKOUT_BRANCH $git_checkout_branch

# Install vale (scripts/lint-doc.sh dependency)
COPY --from=vale-source /bin/vale /usr/bin/vale

# Install GDK and dependencies
COPY --chown=gitpod bootstrap-gitpod-image.sh /tmp

RUN parent_path=$(dirname "$0")
# shellcheck source=support/ci/functions.sh
RUN source "${parent_path}"/functions.sh
# shellcheck disable=SC2119
RUN init

# `gitpod/workspace-base` image sets USER to `gitpod`,
# making commands below run under this user

RUN bash /tmp/bootstrap-gitpod-image.sh
RUN rm -rf ${HOME}/gitlab-development-kit/gitlab

# Setup gitpod related startup scripts
COPY --chown=gitpod 91-gitlab-env /home/gitpod/.bashrc.d/
# these are used in GitLab's `.gitpod.yml`
COPY --chown=gitpod startup-scripts /home/gitpod/
