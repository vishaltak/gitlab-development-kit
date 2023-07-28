#!/usr/bin/env bash

function section_start () {
  local section_title="${1}"
  local section_description="${2:-$section_title}"

  echo -e "section_start:$(date +%s):${section_title}[collapsed=true]\r\e[0K${section_description}"
}

function section_end () {
  local section_title="${1}"

  echo -e "section_end:$(date +%s):${section_title}\r\e[0K"
}

function display_debugging() {
  if [ "${GDK_DEBUG}" = "1" ] || [ "${GDK_DEBUG}" = "true" ]; then
    section_start "debugging-info" "Debugging info"

    debugging_commands

    section_end "debugging-info"
  fi

  true
}

function execute_command() {
  command="${*}"

  echo "${command}"
  echo "-------------------------------------------------------------------------------"
  eval "${command}"
  echo
}

function debugging_commands() {
  execute_command whoami
  execute_command ulimit -a
  execute_command /sbin/sysctl -a
  execute_command nproc
  execute_command df -h
  execute_command free -m
  execute_command 'env | grep -Ev "TOKEN|PASSWORD|LICENSE|KEY"'
  execute_command pwd
  execute_command ls -la
}
