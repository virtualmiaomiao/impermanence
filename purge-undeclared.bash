#!/usr/bin/env bash

set -o nounset            # Fail on use of unset variable.
set -o errexit            # Exit on command failure.
set -o pipefail           # Exit on failure of any command in a pipeline.
set -o errtrace           # Trap errors in functions and subshells.
shopt -s inherit_errexit  # Inherit the errexit option status in subshells.
shopt -s nullglob dotglob

trap 'echo Error when executing ${BASH_COMMAND} at line ${LINENO}! >&2' ERR

if [[ $# -lt 2 ]]; then
  echo "Error: 'purge-undeclared.bash' requires at least two args: baseDir and debug." >&2
  exit 1
fi

baseDir="$1"
debug="$2"
shift 2

if (( debug )); then
  set -o xtrace
fi

if [[ ! -d "$baseDir" ]]; then
  exit 0
fi

echo "Impermanence: Purging undeclared files and directories in $baseDir..."

declare -A allowed_paths

current_type=""
for arg in "$@"; do
  if [[ "$arg" == "--dirs" || "$arg" == "--files" || "$arg" == "--parents" ]]; then
    current_type="${arg#--}"
    continue
  fi
  if [[ -n "$current_type" ]]; then
    if [[ "${allowed_paths[$arg]:-}" != "dirs" ]]; then
      allowed_paths["$arg"]="$current_type"
    fi
  fi

done
purge_tree() {
  local parent="$1"
  local item

  for item in "$parent"/*; do
    [[ "${item##*/}" == "." || "${item##*/}" == ".." ]] && continue

    case "${allowed_paths[$item]:-}" in
      "dirs")
        continue
        ;;
      "files")
        continue
        ;;
      "parents")
        purge_tree "$item"
        ;;
      *)
        if (( debug )); then
          echo "Removing undeclared path: $item"
        fi
        # rm -rf "$item"
        ;;
    esac
  done
}

purge_tree "$baseDir"
