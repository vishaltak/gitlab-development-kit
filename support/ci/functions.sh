# shellcheck shell=bash

GDK_CHECKOUT_PATH="$(pwd)/gdk"

if [[ ${GDK_DEBUG} == "1" ]]; then
  export GIT_CURL_VERBOSE=1
fi

cd_into_checkout_path() {
  cd "${GDK_CHECKOUT_PATH}/${1}" || exit
}

init() {
  clone

  if [ -n "${1}" ]; then
    checkout "${1}"
  else
    if [ -n "${CI_MERGE_REQUEST_SOURCE_BRANCH_SHA}" ]; then
      checkout "${CI_MERGE_REQUEST_SOURCE_BRANCH_SHA}"
    else
      checkout "${CI_COMMIT_SHA}"
    fi
  fi

  install_gem
  install
}

clone() {
  git clone https://gitlab.com/gitlab-org/gitlab-development-kit.git "${GDK_CHECKOUT_PATH}"
  # TODO: Touching .gdk-install-root will be redundant shortly.
  echo "${GDK_CHECKOUT_PATH}" > "${GDK_CHECKOUT_PATH}/.gdk-install-root"
}

install_gem() {
  cd_into_checkout_path "gem"

  gem build gitlab-development-kit.gemspec
  gem install gitlab-development-kit-*.gem
  gdk
}

checkout() {
  cd_into_checkout_path

  # $CI_MERGE_REQUEST_SOURCE_PROJECT_URL only exists in pipelines generated in merge requests.
  if [ -n "${CI_MERGE_REQUEST_SOURCE_PROJECT_URL}" ]; then
    git remote set-url origin "${CI_MERGE_REQUEST_SOURCE_PROJECT_URL}.git"
  fi

  git fetch
  git checkout "${1}"
}

set_gitlab_upstream() {
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
}

install() {
  cd_into_checkout_path

  echo "> Installing GDK.."
  gdk install
  set_gitlab_upstream
}

update() {
  cd_into_checkout_path

  echo "> Updating GDK.."
  # we use `make update` instead of `gdk update` to ensure the working directory
  # is not reset to the default branch.
  make update
  set_gitlab_upstream
  restart
}

reconfigure() {
  cd_into_checkout_path

  echo "> Running gdk reconfigure.."
  gdk reconfigure
}

reset_data() {
  cd_into_checkout_path

  echo "> Running gdk reset-data.."
  gdk reset-data
}

pristine() {
  cd_into_checkout_path

  echo "> Running gdk pristine.."
  gdk pristine
}

start() {
  cd_into_checkout_path

  echo "> Starting up GDK.."
  gdk start
}

stop() {
  cd_into_checkout_path

  echo "> Stopping GDK.."
  gdk stop || true

  sleep 5
  # shellcheck disable=SC2009
  ps -ef | grep "[r]unsv" || true
}

restart() {
  cd_into_checkout_path

  echo "> Restarting GDK.."

  stop_start

  echo "> Upgrading PostgreSQL data directory if necessary.."
  support/upgrade-postgresql

  stop_start
}

stop_start() {
  cd_into_checkout_path

  stop
  status
  start
}

status() {
  cd_into_checkout_path

  echo "> Running gdk status.."
  gdk status || true
}

doctor() {
  cd_into_checkout_path

  echo "> Running gdk doctor.."
  gdk doctor || true
}

test_url() {
  cd_into_checkout_path

  sleep 30
  # QUIET=false support/test_url || QUIET=false support/test_url
  support/ci/test_url
}
