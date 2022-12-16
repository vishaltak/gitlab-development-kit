# shellcheck shell=bash

CDPATH=''
ROOT_PATH="$(cd "$(dirname "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}")/.." || exit ; pwd -P)"

CURRENT_ASDF_DIR="${ASDF_DIR:-${HOME}/.asdf}"
CURRENT_ASDF_DATA_DIR="${ASDF_DATA_DIR:-${HOME}/.asdf}"
DEFAULT_GEMS_PATH="${HOME}/.default-gems"

export PATH="${CURRENT_ASDF_DIR}/bin:${CURRENT_ASDF_DATA_DIR}/shims:${PATH}"

CPU_TYPE=$(arch -arm64 uname -m 2> /dev/null || uname -m)

# Add supported linux platform IDs extracted from /etc/os-release into the
# appropriate varible variables below. SUPPORTED_LINUX_PLATFORMS ends up containing
# all supported platforms and is displayed to the user if their platform is not
# supported, so you can format the ID to be 'Ubuntu' instead of 'ubuntu'
# (which is how ID appears in /etc/os-release) so it's rendered nicely to the
# user. When comparing the user's platform ID against SUPPORTED_LINUX_PLATFORMS, we
# ensure the check is not case sensitive which means we get the best of both
# worlds.
#
# Check first if the BASH version is 3.2 (macOS's default) because associative arrays were introducted in version 4.
# shellcheck disable=SC2076
if [[ ${BASH_VERSION%%.*} -gt 3 ]]; then
  declare -A SUPPORTED_LINUX_PLATFORMS=( ['ubuntu']='Ubuntu Pop neon' \
                                   ['debian']='Debian PureOS' \
                                   ['arch']='Arch Manjaro' \
                                   ['fedora']='Fedora RHEL' )
fi

GDK_CACHE_DIR="${ROOT_PATH}/.cache"
GDK_BOOTSTRAPPED_FILE="${GDK_CACHE_DIR}/.gdk_bootstrapped"
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

ensure_line_in_file() {
  grep -qxF "$1" "$2" || echo "$1" >> "$2"
}

asdf_configure() {
  if ! asdf_enabled; then
    return 0
  fi

  gems=(gitlab-development-kit bundler)

  for gem in "${gems[@]}"
  do
    if ! echo_if_unsuccessful ensure_line_in_file "$gem" "${DEFAULT_GEMS_PATH}"; then
      return 1
    fi
  done

  return 0
}

asdf_install_update_plugins() {
  cut -d ' ' -f 1 .tool-versions | grep -Ev "^#|^$" | while IFS= read -r plugin
  do
    asdf plugin update "${plugin}" || asdf plugin add "${plugin}"
  done

  # Install Node.js' OpenPGP key
  if [[ ! -f "${HOME}/.gnupg/asdf-nodejs.gpg" ]]; then
    bash -c "${CURRENT_ASDF_DATA_DIR}/plugins/nodejs/bin/import-release-team-keyring" > /dev/null 2>&1
  fi

  return 0
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

gdk_install_gdk_clt() {
  if [[ -x "${ROOT_PATH}/bin/gdk" && "$("${ROOT_PATH}/bin/gdk" config get gdk.use_bash_shim)" == "true" ]]; then
    echo "INFO: Installing gdk shim.."
    gdk_install_shim
    gdk_uninstall_gdk_gems
  else
    echo "INFO: Installing gitlab-development-kit Ruby gem.."
    gdk_install_gem
  fi
}

gdk_install_shim() {
  local shim_source="${ROOT_PATH}/bin/gdk"
  local shim_dest="/usr/local/bin"
  local shim_full_dest="${shim_dest}/gdk"
  local command="cp -f ${shim_source} ${shim_full_dest}"

  if cmp -s "${shim_source}" "${shim_full_dest}"; then
    return 0
  fi

  if [[ -w "${shim_dest}" ]]; then
    eval "${command}"
  else
    echo "INFO: Sudo needed to be able to create/update '${shim_full_dest}'"
    eval "sudo ${command}"
  fi

  return 0
}

gdk_uninstall_gdk_gems() {
  if ! asdf_enabled; then
    return 0
  fi

  echo "INFO: Uninstalling any gitlab-development-kit gems.."

  find "${CURRENT_ASDF_DATA_DIR}"/installs/ruby ! -path "${CURRENT_ASDF_DATA_DIR}"/installs/ruby -type d -maxdepth 1 -exec basename {} \; | while read -r ruby_version
  do
    cmd="ASDF_RUBY_VERSION=${ruby_version} gem uninstall --force -x gitlab-development-kit > /dev/null"
    if ! eval "${cmd}"; then
      return 1
    fi
  done

  hash -r
  asdf reshim ruby
}

gdk_install_gem() {
  (
    cd "${ROOT_PATH}/gem" || return 1

    rm -f gitlab-development-kit-*.gem

    if ! echo_if_unsuccessful prefix_with_asdf_if_available gem build gitlab-development-kit.gemspec; then
      return 1
    fi

    if ! echo_if_unsuccessful prefix_with_asdf_if_available gem install gitlab-development-kit-*.gem; then
      return 1
    fi

    return 0
  )
}

update_rubygems_gem() {
  gem update --system --no-document --silent
}

configure_ruby() {
  update_rubygems_gem
}

configure_ruby_bundler_for_gitlab() {
  (
    cd "${ROOT_PATH}/gitlab" || return 0

    if asdf_command_enabled "pg_config"; then
      current_pg_config_location=$(asdf which pg_config)
    else
      current_pg_config_location=$(command -v pg_config)
    fi

    bundle config build.pg "--with-pg-config=${current_pg_config_location}"
    bundle config unset build.gpgme

    if [[ "${OSTYPE}" == "darwin"* ]]; then
      bundle config build.re2 --with-re2-dir="$(brew --prefix re2)"

      clang_version=$(clang --version | head -n1 | awk '{ print $4 }' | awk -F'.' '{ print $1 }')

      if [[ ${clang_version} -ge 13 ]]; then
        bundle config build.thrift --with-cppflags="-Wno-error=compound-token-split-by-macro"
      fi

      bundle config unset build.ffi-yajl
    fi
  )
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
  platform=$(get_platform)

  if [[ "$platform" == "" ]]; then
    return 1
  elif [[ "$platform" == "darwin" ]]; then
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
  fi
  return 0
}

common_preflight_checks() {
  echo "INFO: Performing common preflight checks.."

  if ! ensure_supported_platform; then
    echo
    echo "ERROR: Unsupported platform. The list of supported platforms are:" >&2
    echo "INFO:" >&2
    for platform in "${SUPPORTED_LINUX_PLATFORMS[@]}"; do
      echo "INFO: - $platform" >&2
    done
    echo "INFO: - macOS" >&2
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

# Outputs: Writes detected platform to stdout
get_platform() {
  platform=""

  # $OSTYPE is an internal Bash variable
  # https://tldp.org/LDP/abs/html/internalvariables.html
  if [[ "${OSTYPE}" == "darwin"* ]]; then
    platform="darwin"

  elif [[ "${OSTYPE}" == "linux-gnu"* ]]; then
    os_id_like=$(awk -F= '$1=="ID_LIKE" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
    os_id=$(awk -F= '$1=="ID" { gsub(/"/, "", $2); print $2 ;}' /etc/os-release)
    [[ -n ${os_id_like} ]] || os_id_like=unknown

    shopt -s nocasematch

    for key in ${!SUPPORTED_LINUX_PLATFORMS[*]}; do
      if [[ ${SUPPORTED_LINUX_PLATFORMS[${key}]} =~ ${os_id}|${os_id_like} ]]; then
        platform=$key
      fi
    done

    shopt -u nocasematch
  fi
  echo "$platform"
}

setup_platform() {
  platform=$(get_platform)

  echo "INFO: Setting up '$platform' platform.."
  if platform_files_checksum_matches; then
    echo "INFO: This GDK has already had platform packages installed."
    echo "INFO: Remove '${GDK_PLATFORM_SETUP_FILE}' to force execution."

    return 0
  fi

  if [[ "${platform}" == "darwin" ]]; then
    if setup_platform_darwin; then
      mark_platform_as_setup "Brewfile"
    else
      return 1
    fi
  else
    if [[ "${platform}" == "debian" || "${platform}" == "ubuntu" ]]; then
      if install_apt_packages "packages_${platform}.txt"; then
        mark_platform_as_setup "packages_${platform}.txt"
      else
        return 1
      fi
    elif [[ "${platform}" == "arch" ]]; then
      if setup_platform_linux_arch_like "packages_${platform}.txt"; then
        mark_platform_as_setup "packages_${platform}.txt"
      else
        return 1
      fi
    elif [[ "${platform}" == "fedora" ]]; then
      if setup_platform_linux_fedora_like "packages_${platform}.txt"; then
        mark_platform_as_setup "packages_${platform}.txt"
      else
        return 1
      fi
    fi
  fi
}


bootstrap_files_checksum_matches() {
  if [[ ! -f "${GDK_BOOTSTRAPPED_FILE}" ]]; then
    return 1
  fi

  # sha256sum _may_ not exist at this point
  if ! which sha256sum > /dev/null 2>&1; then
    return 1
  fi

  sha256sum --check --status "${GDK_BOOTSTRAPPED_FILE}" 2> /dev/null
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

install_apt_packages() {
  local platform_file="${1}"

  if ! echo_if_unsuccessful sudo apt-get update; then
    return 1
  fi

  # shellcheck disable=SC2046
  if ! sudo DEBIAN_FRONTEND=noninteractive apt-get install -y $(sed -e 's/#.*//' "${platform_file}"); then
    return 1
  fi

  return 0
}

setup_platform_linux_arch_like() {
  local platform_file="${1}"

  if ! echo_if_unsuccessful sudo pacman -Syy; then
    return 1
  fi

  # shellcheck disable=SC2046
  if ! sudo pacman -S --needed --noconfirm $(sed -e 's/#.*//' "${platform_file}"); then
    return 1
  fi

  # Check for runit, which needs to be manually installed from AUR.
  if ! echo_if_unsuccessful which runit; then
    echo "INFO: Installing runit"
    (
      cd /tmp || return 1
      git clone --depth 1 https://aur.archlinux.org/runit-systemd.git
      cd runit-systemd || return 1
      makepkg -sri --noconfirm
    )
  fi

  return 0
}

setup_platform_linux_fedora_like() {
  local platform_file="${1}"

  if ! echo_if_unsuccessful sudo dnf module enable postgresql:12 -y; then
    return 1
  fi

  # shellcheck disable=SC2046
  if ! sudo dnf install -y $(sed -e 's/#.*//' "${platform_file}" | tr '\n' ' '); then
    return 1
  fi

  if ! echo_if_unsuccessful which runit; then
    echo "INFO: Installing runit into /opt/runit/"
    (
      cd /tmp || return 1
      wget http://smarden.org/runit/runit-2.1.2.tar.gz
      tar xzf runit-2.1.2.tar.gz
      cd admin/runit-2.1.2 || return 1
      sed -i -E 's/ -static$//g' src/Makefile || return 1
      ./package/compile || return 1
      ./package/check || return 1
      sudo mkdir -p /opt/runit || return 1
      sudo mv command/* /opt/runit || return 1
      sudo ln -nfs /opt/runit/* /usr/local/bin/ || return 1
    )
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
