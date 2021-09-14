FROM registry.gitlab.com/gitlab-org/gitlab-development-kit/asdf-bootstrapped-verify:main as base

ENV CI_COMMIT_SHA=main
ENV CI_REPOSITORY_URL=https://gitlab.com/gitlab-org/gitlab-development-kit.git

SHELL ["/bin/bash", "-c"]

RUN git clone $CI_REPOSITORY_URL

WORKDIR /home/gdk/gitlab-development-kit
RUN source support/ci/functions.sh && \
    init && \
    checkout "${CI_COMMIT_SHA}" && \
    install_gem
RUN source support/ci/functions.sh && \
    install && \
    doctor

WORKDIR /home/gdk/gitlab-development-kit/gitlab-development-kit
COPY qa/gdk.yml gdk.yml
COPY qa/launch launch

RUN gdk start && support/ci/test_url && gdk reconfigure && gdk stop

FROM registry.gitlab.com/gitlab-org/gitlab-development-kit/asdf-bootstrapped-verify:main as runtime

EXPOSE 80
EXPOSE 22

WORKDIR /home/gdk/

COPY --from=base /home/gdk/gitlab-development-kit/gitlab-development-kit ./

CMD ["./launch"]
