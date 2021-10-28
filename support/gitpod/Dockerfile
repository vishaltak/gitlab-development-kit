FROM jdkato/vale AS vale-source

FROM gitpod/workspace-base

# Install vale (scripts/lint-doc.sh dependency)
COPY --from=vale-source /bin/vale /usr/bin/vale

# Install gdk and dependencies
# ENV ENABLE_BOOTSNAP 0
# ENV BOOTSNAP_CACHE_DIR /tmp
COPY bootstrap-gitpod-image.sh /
RUN bash /bootstrap-gitpod-image.sh

# Setup gitpod related startup scripts
COPY 91-gitlab-env /home/gitpod/.bashrc.d/
COPY startup-scripts /home/gitpod/
