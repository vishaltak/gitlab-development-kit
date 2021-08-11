#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

COLOR_RED="\e[31m"
COLOR_GREEN="\e[32m"
COLOR_RESET="\e[39m"

FAILING_FILES=0
TOTAL_FILES=0

function check_file {
  local file
  file="$1"
  TOTAL_FILES=$((TOTAL_FILES + 1))
  if [ "$(head -n1 "$file")" != "---" ]; then
    printf "\n${COLOR_RED}Documentation metadata missing in %s.${COLOR_RESET}" "$file" >&2
    FAILING_FILES=$((FAILING_FILES + 1))
  fi
}

while IFS= read -r -d '' file; do
  check_file "$file"
done < <(find "doc" -name "*.md" -type f -print0)

if [ "$FAILING_FILES" -gt 0 ]; then
  # shellcheck disable=SC2059
  printf "\n${COLOR_RED}Documentation metadata is missing in ${FAILING_FILES} of ${TOTAL_FILES} documentation files.${COLOR_RESET} For more information, see https://docs.gitlab.com/ee/development/documentation/#metadata.\n" >&2
  exit 1
else
  # shellcheck disable=SC2059
  printf "${COLOR_GREEN}Documentation metadata found in ${TOTAL_FILES} documentation files.${COLOR_RESET}\n"
  exit 0
fi
