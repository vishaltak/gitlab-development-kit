#!/usr/bin/env bash

function retry() {
  retry_times_sleep 2 3 "$@"
}

function retry_times_sleep() {
  number_of_retries="$1"
  shift
  sleep_seconds="$1"
  shift

  if "$@"; then
    return 0
  fi

  for i in $(seq "${number_of_retries}" -1 1); do
    sleep "$sleep_seconds"s
    echo "[$(date '+%H:%M:%S')] Retrying $i..."
    if "$@"; then
      return 0
    fi
  done

  return 1
}

# Retry after 2s, 4s, 8s, 16s, 32, 64s, 128s
function retry_exponential() {
  if "$@"; then
    return 0
  fi

  local sleep_time=0
  # The last try will be after 2**7 = 128 seconds (2min8s)
  for i in 1 2 3 4 5 6 7; do
    sleep_time=$((2 ** i))

    echo "Sleep for $sleep_time seconds..."
    sleep $sleep_time
    echo "[$(date '+%H:%M:%S')] Attempt #$i..."
    if "$@"; then
      return 0
    fi
  done

  return 1
}

function section_start () {
  local section_title="${1}"
  local section_description="${2:-$section_title}"

  echo -e "section_start:$(date +%s):${section_title}[collapsed=true]\r\e[0K${section_description}"
}

function section_end () {
  local section_title="${1}"

  echo -e "section_end:$(date +%s):${section_title}\r\e[0K"
}

function run_timed_command() {
  local cmd="${1}"
  local metric_name="${2:-no}"
  local timed_metric_file
  local start
  start=$(date +%s)

  echosuccess "\$ ${cmd}"
  eval "${cmd}"

  local ret
  ret=$?
  local end
  end=$(date +%s)
  local runtime
  runtime=$((end-start))

  if [[ $ret -eq 0 ]]; then
    echosuccess "==> '${cmd}' succeeded in ${runtime} seconds."

    if [[ "${metric_name}" != "no" ]]; then
      timed_metric_file="$(timed_metric_file "${metric_name}")"
      echo "# TYPE ${metric_name} gauge" > "${timed_metric_file}"
      echo "# UNIT ${metric_name} seconds" >> "${timed_metric_file}"
      echo "${metric_name} ${runtime}" >> "${timed_metric_file}"
    fi

    return 0
  else
    echoerr "==> '${cmd}' failed (${ret}) in ${runtime} seconds."
    return $ret
  fi
}

function run_timed_command_with_metric() {
  local cmd="${1}"
  local metric_name="${2}"
  local metrics_file=${METRICS_FILE:-metrics.txt}

  run_timed_command "${cmd}" "${metric_name}"

  local ret=$?

  cat "$(timed_metric_file "${metric_name}")" >> "${metrics_file}"

  return $ret
}

function timed_metric_file() {
  local metric_name="${1}"

  echo "$(pwd)/tmp/duration_${metric_name}.txt"
}

function echoerr() {
  local header="${2:-no}"

  if [ "${header}" != "no" ]; then
    printf "\n\033[0;31m** %s **\n\033[0m" "${1}" >&2;
  else
    printf "\033[0;31m%s\n\033[0m" "${1}" >&2;
  fi
}

function echoinfo() {
  local header="${2:-no}"

  if [ "${header}" != "no" ]; then
    printf "\n\033[0;33m** %s **\n\033[0m" "${1}" >&2;
  else
    printf "\033[0;33m%s\n\033[0m" "${1}" >&2;
  fi
}

function echosuccess() {
  local header="${2:-no}"

  if [ "${header}" != "no" ]; then
    printf "\n\033[0;32m** %s **\n\033[0m" "${1}" >&2;
  else
    printf "\033[0;32m%s\n\033[0m" "${1}" >&2;
  fi
}

function display_debugging() {
  if [ "${GDK_DEBUG}" = "1" ] || [ "${GDK_DEBUG}" = "true" ]; then
    section_start "debugging-info" "Debugging info"

    debugging_commands

    section_end "debugging-info"
  fi
}

function debugging_commands() {
  whoami;
  ulimit -a;
  /sbin/sysctl -a;
  nproc;
  df -h;
  free -m;
  env | grep -Ev "TOKEN|PASSWORD|LICENSE|KEY";
  pwd;
  ls -la;
}
