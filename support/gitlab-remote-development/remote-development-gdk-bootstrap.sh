#!/usr/bin/env bash

# This script needs to be run to configure gdk.yml

# It takes a look at the environment variables set by kubernetes
# and the workspace and attempts to configure gdk.yml accordingly.

set -eo pipefail

# See https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html#index-SECONDS for the usage of seconds.
SECONDS=0

LOG_FILE="execution_times.log"
MY_IP=$(hostname -I | tr -d '[:space:]')
GDK_PORT=$(env | grep SERVICE_PORT_GDK_ | awk -F= '{ print $2 }')
GDK_URL=$(echo "${GL_WORKSPACE_DOMAIN_TEMPLATE}" | sed -r 's/\$\{PORT\}/'${GDK_PORT}'/')
PROJECT_PATH=${PWD}
WORKSPACE_DIR_NAME=/workspace

measure_time() {
  local start=$SECONDS
  "$@"
  local duration=$((SECONDS - start))
  echo "$1: $duration seconds" >> "$LOG_FILE"
}

configure_gdk() {
  echo "# --- Setting up GDK Config ---"
  gdk config set listen_address "${MY_IP}"
  gdk config set gitlab.rails.hostname "${GDK_URL}"
  gdk config set gitlab.rails.https.enabled true
  gdk config set gitlab.rails.port 443
  gdk config set webpack.host "${MY_IP}"
  gdk config set webpack.live_reload false
  gdk config set webpack.static false
}

check_inotify() {
  INOTIFY_WATCHES=$(cat /proc/sys/fs/inotify/max_user_watches)
  INOTIFY_WATCHES_THRESHOLD=524288
  if [[ ${INOTIFY_WATCHES} -lt ${INOTIFY_WATCHES_THRESHOLD} ]]; then
    echo "fs.inotify.max_user_watches is less than ${INOTIFY_WATCHES_THRESHOLD}. Please set this on your node."
    echo "See https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues/307 and"
    echo "https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/advanced.md#install-dependencies-for-other-linux-distributions"
    echo "for details."

    exit 1
  fi
}

install_gems() {
  cd "${PROJECT_PATH}"
  echo "Installing Gems in ${PROJECT_PATH}"
  bundle install
  cd gitlab
  echo "Installing Gems in ${PROJECT_PATH}/gitlab"
  bundle install
  cd "${PROJECT_PATH}"
}

clone_gitlab() {
  echo "Cloning gitlab-org/gitlab"
  git clone https://gitlab.com/gitlab-org/gitlab.git
  cp "${WORKSPACE_DIR_NAME}/gitlab-development-kit/secrets.yml" gitlab/config
}

copy_items_from_bootstrap() {
  interesting_items=(".cache" "clickhouse" "consul" "gdk-config.mk"
    "gitaly" ".gitlab-bundle" ".gitlab-lefthook" "gitlab-pages" "gitlab-runner-config.toml"
    "gitlab-shell" ".gitlab-shell-bundle" ".gitlab-translations" ".gitlab-yarn" 
    "localhost.crt" "localhost.key" "log" "minio" "pgbouncers" "postgresql" "Procfile"
    "registry" "registry_host.crt" "registry_host.key" "secrets.yml" "services" "sv"
  )
  
  for item in "${interesting_items[@]}"; do
    echo "Moving bootstrapped GDK item: ${item}"
    mv "${WORKSPACE_DIR_NAME}/gitlab-development-kit/${item}" .
  done
}

reconfigure_and_migrate() {
  install_gems

  gdk reconfigure
  
  make gitlab-db-migrate
  gdk stop
}

update_gdk() {
  gdk update
}

restart_gdk() {
  gdk stop
  gdk start
}

measure_time configure_gdk
measure_time check_inotify
measure_time clone_gitlab
measure_time copy_items_from_bootstrap
measure_time reconfigure_and_migrate
measure_time update_gdk
measure_time restart_gdk

DURATION=$SECONDS
echo "Total Duration: $(($DURATION / 60)) minutes and $(($DURATION % 60)) seconds."
echo "Execution times for each function:"
cat "$LOG_FILE"

echo "Success! You can access your GDK here: https://${GDK_URL}"
