# shellcheck shell=bash

parent_path=$(dirname "$0")

# shellcheck source=support/ci/utils.sh
source "${parent_path}"/utils.sh

GDK_CHECKOUT_PATH="${HOME}/gdk"

if [[ ${GDK_DEBUG} == "1" ]]; then
  export GIT_CURL_VERBOSE=1
fi

cd_into_checkout_path() {
  cd "${GDK_CHECKOUT_PATH}/${1}" || exit
}

init() {
  section_start "init"
  sudo /sbin/sysctl fs.inotify.max_user_watches=1048576

  install_gdk_clt
  section_end "init"
}

install_gdk_clt() {
  section_start "install_gdk_clt"
  if [[ "$("${GDK_CHECKOUT_PATH}/bin/gdk" config get gdk.use_bash_shim)" == "true" ]]; then
    echo "INFO: Installing gdk shim.."
    install_shim
  else
    echo "INFO: Installing gitlab-development-kit Ruby gem.."
    install_gem
  fi
  section_end "install_gdk_clt"
}

install_shim() {
  section_start "install_shim"
  cp -f "${GDK_CHECKOUT_PATH}/bin/gdk" /usr/local/bin
  section_end "install_shim"
}

install_gem() {
  section_start "install_gem"
  cd_into_checkout_path "gem"

  gem build gitlab-development-kit.gemspec
  gem install gitlab-development-kit-*.gem
  section_end "install_gem"
}

checkout() {
  section_start "checkout"
  cd_into_checkout_path

  # $CI_MERGE_REQUEST_SOURCE_PROJECT_URL only exists in pipelines generated in merge requests.
  if [ -n "${CI_MERGE_REQUEST_SOURCE_PROJECT_URL}" ]; then
    git remote set-url origin "${CI_MERGE_REQUEST_SOURCE_PROJECT_URL}.git"
  fi

  git fetch
  git checkout "${1}"
  section_end "checkout"
}

set_gitlab_upstream() {
  section_start "set_gitlab_upstream"
  cd_into_checkout_path "gitlab"

  local remote_name
  local default_branch

  remote_name="upstream"
  default_branch="master"

  if git remote | grep -Eq "^${remote_name}$"; then
    echo "Remote ${remote_name} already exists in $(pwd)."
    return
  fi

  git remote add "${remote_name}" "https://gitlab.com/gitlab-org/gitlab.git"

  git remote set-url --push "${remote_name}" none # make 'upstream' fetch-only
  echo "Fetching ${default_branch} from ${remote_name}..."

  git fetch "${remote_name}" ${default_branch}

  # check if the default branch already exists
  if git show-ref --verify --quiet refs/heads/${default_branch}; then
    git branch --set-upstream-to="${remote_name}/${default_branch}" ${default_branch}
  else
    git branch ${default_branch} "${remote_name}/${default_branch}"
  fi
  section_end "set_gitlab_upstream"
}

install() {
  section_start "install"
  cd_into_checkout_path

  echo "> Installing GDK.."
  gdk install
  set_gitlab_upstream
  section_end "install"
}

update() {
  cd_into_checkout_path

  echo "> Updating GDK.."
  # we use `make update` instead of `gdk update` to ensure the working directory
  # is not reset to the default branch.
  section_start "update"
  make update
  section_end "update"
  set_gitlab_upstream
  restart
}

reconfigure() {
  section_start "reconfigure"
  cd_into_checkout_path

  echo "> Running gdk reconfigure.."
  gdk reconfigure
  section_end "reconfigure"
}

reset_data() {
  section_start "reset_data"
  cd_into_checkout_path

  echo "> Running gdk reset-data.."
  gdk reset-data
  section_end "reset_data"
}

pristine() {
  section_start "pristine"
  cd_into_checkout_path

  echo "> Running gdk pristine.."
  gdk pristine
  section_end "pristine"
}

start() {
  section_start "start"
  cd_into_checkout_path

  echo "> Starting up GDK.."
  gdk start
  section_end "start"
}

stop() {
  section_start "stop"
  cd_into_checkout_path

  echo "> Stopping GDK.."

  # shellcheck disable=SC2009
  ps -ef | grep "[r]unsv" || true

  GDK_KILL_CONFIRM=true gdk kill || true

  # shellcheck disable=SC2009
  ps -ef | grep "[r]unsv" || true
  section_end "stop"
}

restart() {
  cd_into_checkout_path

  echo "> Restarting GDK.."

  stop_start

  section_start "upgrade-postgresql"
  echo "> Upgrading PostgreSQL data directory if necessary.."
  support/upgrade-postgresql
  section_end "upgrade-postgresql"

  stop_start
}

stop_start() {
  cd_into_checkout_path

  stop
  status
  start
}

status() {
  section_start "status"
  cd_into_checkout_path

  echo "> Running gdk status.."
  gdk status || true
  section_end "status"
}

doctor() {
  section_start "doctor"
  cd_into_checkout_path

  echo "> Running gdk doctor.."
  gdk doctor || true
  section_end "doctor"
}

test_url() {
  cd_into_checkout_path

  if [ -z "${GITLAB_LAST_VERIFIED_SHA_PATH}" ]; then
    echo "GITLAB_LAST_VERIFIED_SHA_PATH variable must not be empty and must contain a valid path."
    exit 1
  fi

  status

  retry_times_sleep 120 8 test_url http://127.0.0.1:3000/users/sign_in

  SHA=$(git -C "${GITLAB_DIR}" rev-parse HEAD)
  echosuccess "[$(date '+%H:%M:%S')]: Writing GitLab commit SHA ${SHA} into ${GITLAB_LAST_VERIFIED_SHA_PATH}."
  echo "{\"gitlab_last_verified_sha\": \"${SHA}\"}" > "${GITLAB_LAST_VERIFIED_SHA_PATH}"
}

setup_geo() {
  section_start "setup_geo"
  sudo /sbin/sysctl fs.inotify.max_user_watches=524288

  if [ -n "${CI_MERGE_REQUEST_SOURCE_BRANCH_SHA}" ]; then
    sha="${CI_MERGE_REQUEST_SOURCE_BRANCH_SHA}"
  else
    sha="${CI_COMMIT_SHA}"
  fi

  cd ..
  GITLAB_LICENSE_MODE=test CUSTOMER_PORTAL_URL="https://customers.staging.gitlab.com" gdk/support/geo-install gdk gdk2 "${sha}"
  output=$(cd gdk2/gitlab && bin/rake gitlab:geo:check)

  matchers=(
    "GitLab Geo is enabled ... yes"
    "This machine's Geo node name matches a database record ... yes, found a secondary node named \"gdk2\""
    "GitLab Geo tracking database is correctly configured ... yes"
    "Database replication enabled? ... yes"
    "Database replication working? ... yes"
  )

  for matcher in "${matchers[@]}"; do
    if [[ $output != *${matcher}* ]]; then
      echo "Geo install failed. The string is not found: ${matcher}"
      exit 1
    fi
  done
  section_end "setup_geo"
}
