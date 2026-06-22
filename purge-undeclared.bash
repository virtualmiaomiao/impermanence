#!/usr/bin/env bash

set -o nounset            # Fail on use of unset variable.
set -o errexit            # Exit on command failure.
set -o pipefail           # Exit on failure of any command in a pipeline.
set -o errtrace           # Trap errors in functions and subshells.
shopt -s inherit_errexit  # Inherit the errexit option status in subshells.

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
allowed_paths["$baseDir"]=1

for path in "$@"; do
  allowed_paths["$path"]=1
done

while IFS= read -r -d $'\0' item; do
  if [[ "$item" == "$baseDir" ]]; then
    continue
  fi
  
  if [[ -z "${allowed_paths["$item"]:-}" ]]; then
    if (( debug )); then 
      echo "Removing undeclared path: $item"
    fi
    #rm -rf "$item"
  fi
done < <(find "$baseDir" -depth -mindepth 1 -print0)
