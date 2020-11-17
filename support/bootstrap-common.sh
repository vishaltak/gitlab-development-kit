# shellcheck shell=bash

CURRENT_ASDF_DIR="${ASDF_DIR:-${HOME}/.asdf}"
CURRENT_ASDF_DATA_DIR="${ASDF_DATA_DIR:-$CURRENT_ASDF_DIR}"

export PATH="${CURRENT_ASDF_DIR}/bin:${CURRENT_ASDF_DATA_DIR}/shims:${PATH}"

REQUIRED_BUNDLER_VERSION=$(grep -A1 'BUNDLED WITH' Gemfile.lock | tail -n1 | tr -d ' ')

error() {
  echo
  echo "ERROR: ${1}" >&2
  exit 1
}

echo_if_unsuccessful() {
  output="$("${@}" 2>&1)"

  # shellcheck disable=SC2181
  if [[ $? -ne 0 ]] ; then
    echo "${output}" >&2
    return 1
  fi
}

asdf_reshim() {
  asdf reshim
}

gdk_install_gem() {
  if ! echo_if_unsuccessful asdf exec gem install bundler -v "= ${REQUIRED_BUNDLER_VERSION}"; then
    return 1
  fi

  if ! echo_if_unsuccessful asdf exec gem install gitlab-development-kit; then
    return 1
  fi

  return 0
}

ruby_configure_opts() {
  if [[ "${OSTYPE}" == "darwin"* ]]; then
    brew_openssl_dir=$(brew --prefix openssl)
    brew_readline_dir=$(brew --prefix readline)

    echo "RUBY_CONFIGURE_OPTS=\"--with-openssl-dir=${brew_openssl_dir} --with-readline-dir=${brew_readline_dir}\""
  fi

  return 0
}

configure_ruby_bundler() {
  local current_postgres_version
  current_postgres_version=$(asdf current postgres | awk '{ print $2 }')

  bundle config build.pg "--with-pg-config=${CURRENT_ASDF_DIR}/installs/postgres/${current_postgres_version}/bin/pg_config"
  bundle config build.thin --with-cflags="-Wno-error=implicit-function-declaration"
}

ensure_sudo_available() {
  if [ -z "$(command -v sudo)" ]; then
    echo "ERROR: sudo command not found!" >&2
    return 1
  fi

  return 0
}

ensure_not_root() {
  if [[ ${EUID} -eq 0 ]]; then
    return 1
  fi

  return 0
}

ensure_supported_platform() {
  if [[ "${OSTYPE}" == "darwin"* ]]; then
    return 0
  elif [[ "${OSTYPE}" == "linux-gnu"* ]]; then
    os_id=$(awk -F= '$1=="ID" { print $2 ;}' /etc/os-release)

    if [[ "$os_id" == "ubuntu" || "$os_id" == "debian" ]]; then
      return 0
    fi
  fi

  return 1
}

common_preflight_checks() {
  echo "INFO: Performing common preflight checks."
  if ! ensure_supported_platform; then
    echo
    echo "ERROR: Unsupported platform. Only macOS, Ubuntu, and Debian supported." >&2
    echo "INFO: Please visit https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/master/doc/advanced.md to bootstrap manually." >&2
    return 1
  fi

  if ! ensure_not_root; then
    error "Running as root is not supported."
  fi

  if ! ensure_sudo_available; then
    error "sudo is required, please install." >&2
  fi
}

setup_platform() {
  if [[ "${OSTYPE}" == "darwin"* ]]; then
    if ! setup_platform_macos; then
      return 1
    fi
  elif [[ "${OSTYPE}" == "linux-gnu"* ]]; then
    os_id=$(awk -F= '$1=="ID" { print $2 ;}' /etc/os-release)

    if [[ "${os_id}" == "ubuntu" ]]; then
      if ! setup_platform_linux_with "packages.txt"; then
        return 1
      fi
    elif [[ "${os_id}" == "debian" ]]; then
      if ! setup_platform_linux_with "packages_debian.txt"; then
        return 1
      fi
    fi
  fi
}

setup_platform_linux_with() {
  if ! echo_if_unsuccessful sudo apt-get update; then
    return 1
  fi

  # shellcheck disable=SC2046
  if ! sudo apt-get install -y $(sed -e 's/#.*//' "${1}"); then
    return 1
  fi

  return 0
}

setup_platform_macos() {
  local shell_file ruby_configure_opts

  if [ -z "$(command -v brew)" ]; then
    echo "INFO: Installing Homebrew."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  fi

  if ! brew bundle; then
    return 1
  fi

  if ! echo_if_unsuccessful brew link pkg-config; then
    return 1
  fi

  if ! echo_if_unsuccessful brew pin libffi icu4c readline re2; then
    return 1
  fi

  case $SHELL in
  */zsh)
    shell_file="${HOME}/.zshrc"
    ;;
  *)
    shell_file="${HOME}/.bashrc"
    ;;
  esac

  icu4c_pkgconfig_path="export PKG_CONFIG_PATH=\"/usr/local/opt/icu4c/lib/pkgconfig:\${PKG_CONFIG_PATH}\""
  if ! grep -Fxq "${icu4c_pkgconfig_path}" "${shell_file}"; then
    echo -e "\n# Added by GDK bootstrap\n${icu4c_pkgconfig_path}" >> "${shell_file}"
  fi

  ruby_configure_opts="export $(ruby_configure_opts)"
  if ! grep -Fxq "${ruby_configure_opts}" "${shell_file}"; then
    echo -e "\n# Added by GDK bootstrap\n${ruby_configure_opts}" >> "${shell_file}"
  fi

  if [[ ! -d "/Applications/Google Chrome.app" ]]; then
    if ! brew list --cask google-chrome > /dev/null 2>&1; then
      if ! brew cask install google-chrome; then
        return 1
      fi
    fi
  fi
}
