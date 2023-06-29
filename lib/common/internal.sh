#!/usr/bin/env bash

## All functions are internally use only
## Subject to change

## source bin lib from `lib` directory
## usage: `__asdf_source_bin_lib \
##           "${KC_ASDF_PLUGIN_PATH:?}" \
##           "${KC_ASDF_PLUGIN_ENTRY_NAME//./-}"`
__asdf_source_bin_lib() {
  local ns="source.internal"
  local base="$1" name="$2"
  local path="${base}/lib/bin/${name}.sh"
  if [ -f "$path" ]; then
    kc_asdf_debug "$ns" "sourcing bin:lib (%s)" "$path"
    # shellcheck source=/dev/null
    source "$path"
  else
    kc_asdf_debug "$ns" "cannot found bin:lib to source (%s)" \
      "$path"
  fi
}

## exit with error when input bin is missing default command
## usage: `__asdf_bin_unknown 'download'`
__asdf_bin_unknown() {
  local ns="bin.internal"
  kc_asdf_error "$ns" "missing default for 'bin/%s', kc_asdf_main() is require" "$1"
  exit 1
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
