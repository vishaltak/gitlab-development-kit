# shellcheck shell=bash

CDPATH=''
root_path="$(cd "$(dirname "$0")/.." || exit ; pwd -P)"

CURRENT_ASDF_DIR="${ASDF_DIR:-${HOME}/.asdf}"
CURRENT_ASDF_DATA_DIR="${ASDF_DATA_DIR:-${HOME}/.asdf}"

export PATH="${CURRENT_ASDF_DIR}/bin:${CURRENT_ASDF_DATA_DIR}/shims:${PATH}"

CPU_TYPE=$(arch -arm64 uname -m 2> /dev/null || uname -m)

# Add supported linux platform IDs extracted from /etc/os-release into the
# appropriate varible variables below. SUPPORTED_PLATFORMS ends up containing
# all supported platforms and is displayed to the user if their platform is not
# supported, so you can format the ID to be 'Ubuntu' instead of 'ubuntu'
# (which is how ID appears in /etc/os-release) so it's rendered nicely to the
# user. When comparing the user's platform ID against SUPPORTED_PLATFORMS, we
# ensure the check is not case sensitive which means we get the best of both
# worlds.
#
SUPPORTED_UBUNTU_LIKE_PLATFORMS=('Ubuntu Pop neon')
SUPPORTED_DEBIAN_LIKE_PLATFORMS=('Debian PureOS')
SUPPORTED_ARCH_LIKE_PLATFORMS=('Arch Manjaro')
SUPPORTED_FEDORA_LIKE_PLATFORMS=('Fedora RHEL')
SUPPORTED_OTHER_PLATFORMS=('macOS')

SUPPORTED_PLATFORMS=("${SUPPORTED_OTHER_PLATFORMS[@]}" "${SUPPORTED_UBUNTU_LIKE_PLATFORMS[@]}" "${SUPPORTED_DEBIAN_LIKE_PLATFORMS[@]}" "${SUPPORTED_ARCH_LIKE_PLATFORMS[@]}" "${SUPPORTED_FEDORA_LIKE_PLATFORMS[@]}")

GDK_CACHE_DIR="${root_path}/.cache"
GDK_PLATFORM_SETUP_FILE="${GDK_CACHE_DIR}/.gdk_platform_setup"
GDK_MACOS_ARM64_NATIVE="${GDK_MACOS_ARM64_NATIVE:-true}"

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

asdf_is_available() {
  asdf version > /dev/null 2>&1
}

asdf_enabled() {
  opt_out=$(gdk config get asdf.opt_out 2> /dev/null)

  asdf_is_available && [[ "${opt_out}" != "true" ]]
}

asdf_command_enabled() {
  if ! asdf_enabled; then
    return 1
  fi

  asdf which "$1" > /dev/null 2>&1
}

prefix_with_asdf_if_available() {
  local command

  command="${*}"

  if asdf_command_enabled "$1"; then
    eval "asdf exec ${command}"
  else
    eval "${command}"
  fi
}

asdf_check_rvm_rbenv() {
  # RVM and rbenv can conflict with asdf
  if type rvm > /dev/null 2>&1; then
    return 1
  elif type rbenv > /dev/null 2>&1; then
    return 1
  fi

  return 0
}

ruby_required_bundler_versions() {
  local gemfiles

  gemfiles=(./Gemfile.lock ./gitlab/Gemfile.lock ./gitaly/ruby/Gemfile.lock ./gitlab-shell/Gemfile.lock)
  awk '/BUNDLED WITH/{getline;print $NF;}' "${gemfiles[@]}" 2> /dev/null | sort -r | head -n 1

  return 0
}

ruby_install_required_bundlers() {
  local required_versions

  required_versions=$(ruby_required_bundler_versions)

  for version in ${required_versions}
  do
    if ! prefix_with_asdf_if_available bundle "_${version}_" --version ; then
      prefix_with_asdf_if_available gem install bundler -v "=${version}"
    fi
  done
}

gdk_install_gdk_clt() {
  if [[ "$("${root_path}/bin/gdk" config get gdk.use_bash_shim)" == "true" ]]; then
    echo "INFO: Installing gdk shim.."
    gdk_install_shim
  else
    echo "INFO: Installing gitlab-development-kit Ruby gem.."
    gdk_install_gem
  fi
}

gdk_install_shim() {
  if ! echo_if_unsuccessful cp -f bin/gdk /usr/local/bin/gdk; then
    return 1
  fi
}

gdk_install_gem() {
  if ! echo_if_unsuccessful ruby_install_required_bundlers; then
    return 1
  fi

  if ! echo_if_unsuccessful prefix_with_asdf_if_available gem install gitlab-development-kit; then
    return 1
  fi

  return 0
}

configure_ruby_bundler() {
  if asdf_command_enabled "pg_config"; then
    current_pg_config_location=$(asdf which pg_config)
  else
    current_pg_config_location=$(command -v pg_config)
  fi

  bundle config build.pg "--with-pg-config=${current_pg_config_location}"
  bundle config build.thin --with-cflags="-Wno-error=implicit-function-declaration"
  bundle config build.gpgme --use-system-libraries

  if [[ "${OSTYPE}" == "darwin"* ]]; then
    bundle config build.re2 --with-re2-dir="$(brew --prefix re2)"

    clang_version=$(clang --version | head -n1 | awk '{ print $4 }' | awk -F'.' '{ print $1 }')

    if [[ ${clang_version} -ge 13 ]]; then
      bundle config build.thrift --with-cppflags="-Wno-error=compound-token-split-by-macro"
    fi
  fi
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
    if [[ "${CPU_TYPE}" == "arm64" && "${GDK_MACOS_ARM64_NATIVE}" == "false" ]]; then

      if [[ $(command -v brew) == "/opt/homebrew/bin/brew" ]]; then
        echo "ERROR: Native Apple Silicon (arm64) detected. Rosetta 2 is required. For more information, see https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/advanced.md#macos." >&2
        echo "INFO: Native Apple Silicon support for macOS is coming with https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues/1159." >&2

        return 1
      else
        echo "INFO:" >&2
        echo "INFO: Apple Silicon (arm64) with Rosetta 2 detected." >&2
        echo "INFO:" >&2
        echo "INFO: To see the latest on running the GDK natively on Apple Silicon, visit:" >&2
        echo "INFO: https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues/1159" >&2
        echo "INFO:" >&2
        echo "INFO: To learn more about Rosetta 2, visit:" >&2
        echo "INFO: https://en.wikipedia.org/wiki/Rosetta_(software)#Rosetta_2" >&2
        echo "INFO:" >&2
        echo "INFO: Resuming in 3 seconds.." >&2

        sleep 3
      fi
    fi

    return 0
  elif [[ "${OSTYPE}" == "linux-gnu"* ]]; then
    shopt -s nocasematch

    os_id_like=$(awk -F= '$1=="ID_LIKE" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
    os_id=$(awk -F= '$1=="ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)

    if [[ ${SUPPORTED_PLATFORMS[*]} =~ ${os_id} ]] || [[ ${SUPPORTED_PLATFORMS[*]} =~ ${os_id_like} ]]; then
      shopt -u nocasematch
      return 0
    fi
  fi

  shopt -u nocasematch

  return 1
}

common_preflight_checks() {
  echo "INFO: Performing common preflight checks.."

  if ! ensure_supported_platform; then
    echo
    echo "ERROR: Unsupported platform. The list of supported platforms are:" >&2
    echo "INFO:" >&2
    for platform in "${SUPPORTED_PLATFORMS[@]}"; do
      echo "INFO: - $platform" >&2
    done
    echo "INFO:" >&2
    echo "INFO: If your platform is not listed above, you're welcome to create a Merge Request in the GDK project to add support." >&2
    echo "INFO:" >&2
    echo "INFO: Please visit https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/advanced.md to bootstrap manually." >&2
    return 1
  fi

  if ! ensure_not_root; then
    error "Running as root is not supported."
  fi

  if ! ensure_sudo_available; then
    error "sudo is required, please install." >&2
  fi

  if ! asdf_check_rvm_rbenv; then
    echo "ERROR: RVM or rbenv detected, which can cause issues with asdf." >&2
    echo "INFO: We recommend you uninstall RVM or rbenv, or remove RVM or rbenv from your PATH variable." >&2
    echo "INFO: For more information, see https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/migrate_to_asdf.md." >&2
    exit 1
  fi
}

setup_platform() {
  if platform_files_checksum_matches; then
    echo "INFO: This GDK has already had platform packages installed."
    echo "INFO: Remove '${GDK_PLATFORM_SETUP_FILE}' to force execution."

    return 0
  fi

  if [[ "${OSTYPE}" == "darwin"* ]]; then
    if setup_platform_darwin; then
      mark_platform_as_setup "Brewfile"
    else
      return 1
    fi
  elif [[ "${OSTYPE}" == "linux-gnu"* ]]; then
    os_id_like=$(awk -F= '$1=="ID_LIKE" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
    os_id=$(awk -F= '$1=="ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
    [[ -n ${os_id_like} ]] || os_id_like=unknown

    shopt -s nocasematch

    if [[ ${SUPPORTED_UBUNTU_LIKE_PLATFORMS[*]} =~ ${os_id} ]] || [[ ${SUPPORTED_UBUNTU_LIKE_PLATFORMS[*]} =~ ${os_id_like} ]]; then
      if setup_platform_linux_with "packages_ubuntu.txt"; then
        mark_platform_as_setup "packages_ubuntu.txt"
      else
        shopt -u nocasematch
        return 1
      fi
    elif [[ ${SUPPORTED_DEBIAN_LIKE_PLATFORMS[*]} =~ ${os_id} ]] || [[ ${SUPPORTED_DEBIAN_LIKE_PLATFORMS[*]} =~ ${os_id_like} ]]; then
      if setup_platform_linux_with "packages_debian.txt"; then
        mark_platform_as_setup "packages_debian.txt"
      else
        shopt -u nocasematch
        return 1
      fi
    elif [[ ${SUPPORTED_ARCH_LIKE_PLATFORMS[*]} =~ ${os_id} ]] || [[ ${SUPPORTED_ARCH_LIKE_PLATFORMS[*]} =~ ${os_id_like} ]]; then
      if setup_platform_linux_arch_like_with "packages_arch.txt"; then
        mark_platform_as_setup "packages_arch.txt"
      else
        shopt -u nocasematch
        return 1
      fi
    elif [[ ${SUPPORTED_FEDORA_LIKE_PLATFORMS[*]} =~ ${os_id} ]] || [[ ${SUPPORTED_FEDORA_LIKE_PLATFORMS[*]} =~ ${os_id_like} ]]; then
      if setup_platform_linux_fedora_like_with "packages_fedora.txt"; then
        mark_platform_as_setup "packages_fedora.txt"
      else
        shopt -u nocasematch
        return 1
      fi
    fi
    shopt -u nocasematch
  fi
}

platform_files_checksum_matches() {
  if [[ ! -f "${GDK_PLATFORM_SETUP_FILE}" ]]; then
    return 1
  fi

  # sha256sum _may_ not exist at this point
  if ! which sha256sum > /dev/null 2>&1; then
    return 1
  fi

  sha256sum --check --status "${GDK_PLATFORM_SETUP_FILE}"
}

mark_platform_as_setup() {
  local platform_file="${1}"

  mkdir -p "${GDK_CACHE_DIR}"
  sha256sum "${platform_file}" > "${GDK_PLATFORM_SETUP_FILE}"
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

setup_platform_linux_arch_like_with() {
  if ! echo_if_unsuccessful sudo pacman -Syy; then
    return 1
  fi

  # shellcheck disable=SC2046
  if ! sudo pacman -S --needed --noconfirm $(sed -e 's/#.*//' "${1}"); then
    return 1
  fi

  # Check for runit, which needs to be manually installed from AUR.
  if ! echo_if_unsuccessful which runit; then
    cd /tmp || return 1
    git clone --depth 1 https://aur.archlinux.org/runit-systemd.git
    cd runit-systemd || return 1
    makepkg -sri --noconfirm
  fi

  return 0
}

setup_platform_linux_fedora_like_with() {
  if ! echo_if_unsuccessful sudo dnf module enable postgresql:12 -y; then
    return 1
  fi

  # shellcheck disable=SC2046
  if ! sudo dnf install -y $(sed -e 's/#.*//' "${1}" | tr '\n' ' '); then
    return 1
  fi

  if ! echo_if_unsuccessful which runit; then
    echo "INFO: Installing runit into /opt/runit/"
    cd /tmp || return 1
    wget http://smarden.org/runit/runit-2.1.2.tar.gz
    tar xzf runit-2.1.2.tar.gz
    cd admin/runit-2.1.2 || return 1
    sed -i -E 's/ -static$//g' src/Makefile || return 1
    ./package/compile || return 1
    ./package/check || return 1
    sudo mkdir -p /opt/runit || return 1
    sudo mv command/* /opt/runit || return 1
    sudo ln -s /opt/runit/* /usr/local/bin/ || return 1
  fi

  return 0
}

setup_platform_darwin() {
  local brew_opts

  if [ -z "$(command -v brew)" ]; then
    echo "INFO: Installing Homebrew."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  fi

  if ! brew tap homebrew/cask; then
    return 1
  fi

  # Support running brew under Rosetta 2 on Apple M1 machines
  if [[ "${CPU_TYPE}" == "arm64" && "${GDK_MACOS_ARM64_NATIVE}" == "false" ]]; then
    brew_opts="arch -x86_64"
  else
    brew_opts=""
  fi

  if ! ${brew_opts} brew bundle; then
    return 1
  fi

  if ! echo_if_unsuccessful brew link pkg-config; then
    return 1
  fi

  if [[ ! -d "/Applications/Google Chrome.app" ]]; then
    if ! brew list --cask google-chrome > /dev/null 2>&1; then
      if ! ${brew_opts} brew install google-chrome; then
        return 1
      fi
    fi
  fi
}
