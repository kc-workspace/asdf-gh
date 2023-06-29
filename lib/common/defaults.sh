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

## Print help message header
## usage: `kc_asdf_help_header 'Environment'`
kc_asdf_help_header() {
  printf "# %s\n" "$1"
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

## Fetch redirected location from url
## e.g. `kc_asdf_fetch_location https://google.com`
kc_asdf_fetch_location() {
  local tmpfile
  tmpfile="$(kc_asdf_temp_file)"
  export CURL_OPTIONS=(
    --head
    --write-out "%{url_effective}"
    --output "/dev/null"
  )
  export WGET_OPTIONS=(
    --server-response
    --spider
    --output-file "$tmpfile"
  )

  if ! kc_asdf_fetch "$1"; then
    unset CURL_OPTIONS WGET_OPTIONS
    return 1
  elif [ -f "$tmpfile" ]; then
    sed -n -e "s|^[ ]*Location: *||p" <"$tmpfile" |
      tail -n1 &&
      rm "$tmpfile"
  fi

  unset CURL_OPTIONS WGET_OPTIONS
}

## Download file from input url
## e.g. `kc_asdf_fetch_file https://google.com /tmp/index.html`
kc_asdf_fetch_file() {
  local url="$1" filename="$2"
  export CURL_OPTIONS=(
    --output "$filename"
  )
  export WGET_OPTIONS=(
    --output-file "$filename"
  )

  if ! kc_asdf_fetch "$url"; then
    unset CURL_OPTIONS WGET_OPTIONS
    return 1
  fi
  unset CURL_OPTIONS WGET_OPTIONS
}

## Parse version to major, minor and patch version
## e.g. `read -r major minor patch <<< "$(kc_asdf_parse_version "$version")"`
kc_asdf_parse_version() {
  local version="$1"
  echo "${version//./ }"
}

## Fetch data from url
## usage: `kc_asdf_fetch https://google.com`
## variables:
##   - CURL_OPTIONS=() for curl options
##   - WGET_OPTIONS=() for wget options
##   - GITHUB_API_TOKEN for authentication
kc_asdf_fetch() {
  local ns="fetch.defaults"
  local url="$1"
  local cmd="" options=()

  local token=""
  if [[ "$url" =~ ^https://github.com ]]; then
    token="${GITHUB_API_TOKEN:-}"
    [ -z "$token" ] && token="${GITHUB_TOKEN:-}"
    [ -z "$token" ] && token="${GH_TOKEN:-}"
  fi

  local max_redirs=10

  if command -v "curl" >/dev/null; then
    cmd="curl"
    options+=(
      --fail
      --silent
      --show-error
      --location
      --max-redirs "$max_redirs"
    )
    [ -n "${CURL_OPTIONS:-}" ] &&
      options+=("${CURL_OPTIONS[@]}")
    [ -n "$token" ] &&
      options+=(--header "Authorization: token $token")
  elif command -v "wget" >/dev/null; then
    cmd="wget"
    options+=(
      --quiet
      --max-redirect "$max_redirs"
    )
    [ -n "${WGET_OPTIONS:-}" ] &&
      options+=("${WGET_OPTIONS[@]}")
    [ -n "$token" ] &&
      options+=(--header "Authorization: token $token")
  fi

  [ -z "$cmd" ] &&
    kc_asdf_error "$ns" "fetch command not found (e.g. curl, wget)" &&
    return 1

  if ! kc_asdf_exec "$cmd" "${options[@]}" "$url"; then
    kc_asdf_error "$ns" "fetching %s failed" "$url"
    return 1
  fi
}

## Extract compress file
## usage: `kc_asdf_extract /tmp/file.tar.gz /tmp/file`
kc_asdf_extract() {
  local input="$1" output="$2"
  local ext="${input##*.}"

  if [[ "$ext" == "zip" ]]; then
    kc_asdf_exec unzip -qo "$input" -d "$output"
  else
    kc_asdf_exec tar -xzf \
      "$input" \
      -C "$output" \
      --strip-components "1"
  fi
}

## Unpack package file
## usage: `kc_asdf_unpack /tmp/file.pkg /tmp/file`
kc_asdf_unpack() {
  local ns="unpack.defaults"
  local input="$1" output="$2"

  ! command -v pkgutil >/dev/null &&
    kc_asdf_error "$ns" "cannot package because 'pkgutil' is missing" &&
    return 1

  kc_asdf_debug "$ns" "verifying package signature of %s" "$input"
  local expected="signed by a developer certificate issued by Apple for distribution"
  local signature actual
  signature="$(kc_asdf_exec pkgutil --check-signature "$input")"
  actual="$(echo "$signature" | grep -E '^\s+Status: ' | sed 's/[ ]*Status: //')"

  if [[ "$expected" != "$actual" ]]; then
    kc_asdf_error "$ns" "invalid pkg signature, please recheck (%s)" \
      "$input"
    echo "$signature" >&2
    return 1
  fi

  [ -d "$output" ] &&
    kc_asdf_debug "$ns" "delete output directory first" &&
    rm -r "$output"
  kc_asdf_exec pkgutil --expand-full \
    "$input" "$output"
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

    kc_asdf_debug "$ns" "we will create filename '%s' at %s" \
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

## Validate commands must exist;
## otherwise, it will exit with error
## usage: `kc_asdf_require_commands 'java'`
kc_asdf_require_commands() {
  local ns="req-cmd.defaults"

  kc_asdf_debug "$ns" "current plugins requires [%s] commands" \
    "$*"
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null; then
      kc_asdf_error "$ns" "requires '%s' command but missing" \
        "$cmd"
      exit 1
    fi
  done
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
