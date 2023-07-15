#!/usr/bin/env bash

## All functions are internally use only
## Subject to change

## Loading lib utilities
## e.g. `__asdf_load 'common' 'defaults'`
__asdf_load() {
  local ns="load.internal"
  local type="$1" name path code=0
  local basepath="${KC_ASDF_PLUGIN_PATH:?}/lib/$type"
  shift

  for name in "$@"; do
    path="${basepath}/${name}.sh"
    if [ -f "$path" ]; then
      kc_asdf_debug "$ns" "sourcing %s/%s (%s)" \
        "$type" "$name" "$path"
      # shellcheck source=/dev/null
      source "$path"
    else
      code=1
      kc_asdf_error "$ns" "file '%s' is missing" "$path"
      continue
    fi
  done

  return "$code"
}

## The will exit with error if requirement isn't meet
## e.g. `__asdf_requirement`
__asdf_requirement() {
  local ns="require.internal"
  [ -n "${ASDF_NO_CHECK:-}" ] &&
    kc_asdf_debug "$ns" "\$ASDF_NO_CHECK exist, skipped checking requirement" &&
    return 0

  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null; then
      kc_asdf_error "$ns" "missing required command: '%s'" "$cmd"
      exit 1
    fi
  done
}

## Print log to stderr
## usage: `kc_asdf_log '<level>' '<namespace>' '<format>' '<variables>'`
## variables:
##   - ASDF_LOG_FORMAT="{datetime} [{level}] {namespace} - {message}"
__asdf_log() {
  local level="$1" ns="$2" _format="$3"
  shift 3

  local default="{time} [{level}] {namespace} - {message}"
  local template="${ASDF_LOG_FORMAT:-$default}"

  local variables=(
    "datetime=$(date +"%Y-%m-%d %H:%M:%S")"
    "date=$(date +"%Y-%m-%d")"
    "time=$(date +"%H:%M:%S")"
    "level=$level"
    "namespace=$(printf '%-28s' "$ns")"
    "ns=$ns"
    "message=$_format"
  )

  local format
  format="$(kc_asdf_template "$template" "${variables[@]}")"
  # shellcheck disable=SC2059
  printf "$format\n" "$@" >&2
}

## Execute input command if debug mode enabled
## usage: `__asdf_if_debug echo "hello debugger"`
__asdf_if_debug() {
  [ -z "${DEBUG:-}" ] &&
    return 0
  "$@"
}

## Execute input command if debug mode enabled
## usage: `__asdf_if_not_debug echo "hello normal"`
__asdf_if_not_debug() {
  [ -n "${DEBUG:-}" ] &&
    return 0
  "$@"
}
