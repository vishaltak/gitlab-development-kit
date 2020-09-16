# shellcheck shell=bash

GDK_CHECKOUT_PATH="$(pwd)/gitlab-development-kit"

init() {
  install_gem
  gdk init "${GDK_CHECKOUT_PATH}"
}

install_gem() {
  cd gem || exit
  gem build gitlab-development-kit.gemspec
  gem install gitlab-development-kit-*.gem
}

checkout() {
  cd "${GDK_CHECKOUT_PATH}" || exit
  git remote set-url origin "${CI_REPOSITORY_URL}"
  git fetch
  git checkout "${1}"
}

install() {
  cd "${GDK_CHECKOUT_PATH}" || exit
  echo "> Installing GDK.."
  gdk install shallow_clone=true
  support/set-gitlab-upstream
}

update() {
  cd "${GDK_CHECKOUT_PATH}" || exit
  echo "> Updating GDK.."
  # we use `make update` instead of `gdk update` to ensure the working directory
  # is not reset to master.
  make update
  support/set-gitlab-upstream
  restart
}

start() {
  cd "${GDK_CHECKOUT_PATH}" || exit
  echo "> Starting up GDK.."
  gdk start
}

restart() {
  cd "${GDK_CHECKOUT_PATH}" || exit
  echo "> Restarting GDK.."
  # gdk restart

  gdk stop
  gdk status
   # shellcheck disable=SC2009
  ps -ef | grep runsv
  gdk start
}

doctor() {
  cd "${GDK_CHECKOUT_PATH}" || exit
  echo "> Running gdk doctor.."

  # shellcheck disable=SC1090
  source "${HOME}/.asdf/asdf.sh"
  gdk doctor
}

wait_for_boot() {
  echo "> Waiting 90 secs to give GDK a chance to boot up.."
  sleep 90
}
