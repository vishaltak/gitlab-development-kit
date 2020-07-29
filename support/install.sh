#!/bin/bash -e

root_path="$(dirname "$0")/.."
os_release="$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')"

function install_gdk() {
  mkdir -p /usr/local/bin
  cp ${root_path}/gem/bin/gdk /usr/local/bin
  chmod 755 /usr/local/bin/gdk
}

function install_requirements() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    install_requirements_macos
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    install_requirements_linux
  else
    echo "ERROR: Unsupported platform 😞"
    exit 1
  fi
}

function install_requirements_linux() {
  case ${os_release}

debian
ubuntu
}

function install_requirements_ubuntu() {
  apt-get update && apt install git
}

install_requirements
