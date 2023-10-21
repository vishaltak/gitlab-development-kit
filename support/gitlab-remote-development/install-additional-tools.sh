#!/usr/bin/env bash

set -xeuo pipefail
IFS=$'\n\t'

setup_ssh() {
  # Install sshd
  apt-get update && sudo apt-get upgrade -y
  apt-get install -y openssh-server

  # Create privilege separation directory
  mkdir /run/sshd

  # Create host keys
  ssh-keygen -A

  # Set up SSH keypair for user
  export USER_SSH_DIR=/home/${WORKSPACE_USER}/.ssh
  mkdir -p ${USER_SSH_DIR}
  chmod 700 ${USER_SSH_DIR}
  ssh-keygen -t rsa -b 4096 -f ${USER_SSH_DIR}/id_rsa -N ""
  cp ${USER_SSH_DIR}/id_rsa.pub ${USER_SSH_DIR}/authorized_keys
  chmod 600 ${USER_SSH_DIR}/authorized_keys
  chown -R ${WORKSPACE_USER}:${WORKSPACE_USER} ${USER_SSH_DIR}
}

setup_ssh
