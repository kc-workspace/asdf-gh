#!/usr/bin/env bash

## Base default functions for generic use

## Print error message
## usage: `kc_asdf_error '<namespace>' '<format>' '<variables>'`
## output: 'yyyy-mm-dd hh:mm:ss [ERR] <namespace> - <message>'
kc_asdf_error() {
  __asdf_log "ERR" "$@"
}

## Print warn message
## usage: `kc_asdf_warn '<namespace>' '<format>' '<variables>'`
## output: 'yyyy-mm-dd hh:mm:ss [WRN] <namespace> - <message>'
kc_asdf_warn() {
  __asdf_log "WRN" "$@"
}

## Print info message
## usage: `kc_asdf_info '<namespace>' '<format>' '<variables>'`
## output: 'yyyy-mm-dd hh:mm:ss [INF] <namespace> - <message>'
kc_asdf_info() {
  __asdf_log "INF" "$@"
}

## Print debug message
## usage: `kc_asdf_debug '<namespace>' '<format>' '<variables>'`
## output: 'yyyy-mm-dd hh:mm:ss [INF] <namespace> - <message>'
kc_asdf_debug() {
  __asdf_if_debug \
    __asdf_log "DBG" "$@"
}

## Create start action to client
## usage: `kc_asdf_step '<action_verb>' '<message>' $cmd`
kc_asdf_step() {
  local action="$1" message="$2"
  shift 2

  kc_asdf_info "$action.action" "starting (%s)" "$message"
  if "$@"; then
    kc_asdf_info "$action.action" "completed successfully"
  else
    kc_asdf_error "$action.action" "completed with failure"
    return 1
  fi
}

## Execute input command with debug what executed
## usage: `kc_asdf_exec echo 'run'`
kc_asdf_exec() {
  kc_asdf_debug "exec.defaults" "%s" "$*"
  "$@"
}

## Execute input command if exist, or ignore
## usage: `kc_asdf_optional echo 'run'`
kc_asdf_optional() {
  if ! command -v "$1" >/dev/null; then
    kc_asdf_debug "optional.defaults" "command %s missing, silently ignored" \
      "$1"
  fi

  kc_asdf_exec "$@"
}

## Run input command with dry-run support
## usage: `kc_asdf_run echo 'run'`
## variables:
##   - DRY_RUN | DRYRUN | DRY
kc_asdf_run() {
  if [ -n "${DRY_RUN:-}" ] ||
    [ -n "${DRYRUN:-}" ] ||
    [ -n "${DRY:-}" ]; then
    __asdf_log "DRY" "" "$*"
    return 0
  fi
  "$@"
}

## Loading input addon
## usage: `kc_asdf_load_addon 'system'`
kc_asdf_load_addon() {
  local ns="load-addon.defaults"
  local name loaded=()
  for name in "$@"; do
    if [[ "$KC_ASDF_ADDON_LIST" =~ $name ]]; then
      kc_asdf_debug "$ns" "'%s' addon has been loaded, SKIPPED" \
        "$name"
    else
      __asdf_load "addon" "$name"
      loaded+=("$name")
    fi
  done
  if [ "${#loaded[@]}" -gt 0 ]; then
    KC_ASDF_ADDON_LIST="$KC_ASDF_ADDON_LIST ${loaded[*]}"
  fi
}

## Transfer input to output based on input mode
## usage: `kc_adf_transfer 'copy|move|link' '<input>' '<output>'`
kc_asdf_transfer() {
  local ns="transfer.defaults"
  local mode="$1" input="$2" output="$3"
  kc_asdf_debug "$ns" "transfering '%s' using %s method" \
    "$input" "$mode"

  local type=""
  [ -d "$input" ] &&
    type="directory"
  [ -f "$input" ] &&
    type="file"
  if [ -z "$type" ]; then
    local dir base
    dir="$(dirname "$input")"
    base="$(basename "$input")"
    kc_asdf_error "$ns" "missing '%s'" "$input"
    # shellcheck disable=SC2011
    kc_asdf_error "$ns" "directory contains only [%s]" \
      "$(ls "$dir" | xargs echo)"
    return 1
  fi

  kc_asdf_debug "$ns" "input type is %s" "$type"
  ## If input is file, the output should always contains filename
  ## example:
  ##   valid   : /tmp/test.txt /home/test.txt
  ##   invalid : /tmp/test.txt /home
  if [[ "$type" == "file" ]]; then
    local dir base
    dir="$(dirname "$output")"
    base="$(basename "$output")"

    kc_asdf_debug "$ns" "create '%s' (filename) at %s (target)" \
      "$base" "$dir"
    if ! [ -d "$dir" ]; then
      kc_asdf_debug "$ns" "create missing directory (%s)" "$dir"
      kc_asdf_exec mkdir -p "$dir"
    fi
  fi

  if [[ "$mode" == "copy" ]]; then
    if [[ "$type" == "directory" ]]; then
      kc_asdf_exec cp -r "$input/." "$output"
      return $?
    else
      kc_asdf_exec cp "$input" "$output"
      return $?
    fi
  fi

  if [[ "$mode" == "move" ]]; then
    if [[ "$type" == "directory" ]]; then
      [ -d "$output" ] &&
        kc_asdf_debug "$ns" "target directory cannot exist, removed %s" \
          "$output" &&
        rm -r "$output"
      kc_asdf_exec mv "$input" "$output"
      return $?
    else
      kc_asdf_exec mv "$input" "$output"
      return $?
    fi
  fi

  if [[ "$mode" == "link" ]]; then
    kc_asdf_exec ln -s "$input" "$output"
    return $?
  fi

  kc_asdf_error "$ns" "invalid transfer mode (%s)" "$mode"
  return 1
}

## Parse template with input values
## usage: `kc_asdf_template "{template}" 'template=hello'`
kc_asdf_template() {
  local kv key value
  local template="$1"
  shift
  for kv in "$@"; do
    key="${kv%%=*}"
    value="${kv##*=}"
    template="${template//\{$key\}/$value}"
  done
  printf "%s" "$template"
}

## Check enabled feature
## usage: `kc_asdf_enabled_feature '<feature>' && _exec_feature`
kc_asdf_enabled_feature() {
  local ns="feature.defaults"
  local feature="$1"
  if command -v _kc_asdf_custom_enabled_features >/dev/null; then
    kc_asdf_debug "$ns" "developer custom feature '%s' status" "$feature"
    if ! _kc_asdf_custom_enabled_features "$feature"; then
      kc_asdf_debug "$ns" "feature '%s' has been disabled" "$feature"
      return 1
    fi
  else
    return 0
  fi
}

## Create temp file and return path
## usage: `kc_asdf_temp_file`
kc_asdf_temp_file() {
  mktemp
}

## Create temp file and return path
## usage: `kc_asdf_temp_dir`
kc_asdf_temp_dir() {
  mktemp -d
}

## Check if input is directory and contains some files
## usage: `kc_asdf_present_dir /tmp`
kc_asdf_present_dir() {
  local directory="$1"
  # shellcheck disable=SC2010
  [ -d "$directory" ] &&
    ls -A1q "$directory" | grep -q .
}
