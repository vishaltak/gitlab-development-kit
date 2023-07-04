#!/usr/bin/env bash

# This script needs to be run to configure gdk.yml

# It takes a look at the environment variables set by kubernetes
# and the workspace and attempts to configure gdk.yml accordingly.

set -eo pipefail

MY_IP=$(hostname -I)
GDK_PORT=$(env | grep SERVICE_PORT_GDK_ | awk -F= '{ print $2 }')
GDK_URL=$(echo $GL_WORKSPACE_DOMAIN_TEMPLATE | sed -r 's/\$\{PORT\}/'${GDK_PORT}'/')

cat > gdk.yml << EOF
---
listen_address: ${MY_IP}
gitlab:
  rails:
    hostname: ${GDK_URL}
    https:
      enabled: true
    port: 443
webpack:
  host: ${MY_IP}
  live_reload: false
  static: false
EOF

INOTIFY_WATCHES=$(cat /proc/sys/fs/inotify/max_user_watches)
INOTIFY_WATCHES_THRESHOLD=524288
if [[ ${INOTIFY_WATCHES} -lt ${INOTIFY_WATCHES_THRESHOLD} ]]; then
  echo "fs.inotify.max_user_watches is less than ${INOTIFY_WATCHES_THRESHOLD}. Please set this on your node."
  echo "See https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues/307 and"
  echo "https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/advanced.md#install-dependencies-for-other-linux-distributions"
  echo "for details."
fi

echo "Setup complete, you can now continue to install GitLab using the GDK:"
echo "https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/index.md#use-gdk-to-install-gitlab"
