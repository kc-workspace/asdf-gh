#!/usr/bin/env bash

## Print error message
## usage: `kc_asdf_error 'something went %s' 'wrong'`
kc_asdf_error() {
  kc_asdf_log "ERR" "$@"
}

## Print info message
## usage: `kc_asdf_info 'this is a %s message' 'info'`
kc_asdf_info() {
  kc_asdf_log "INF" "$@"
}

## Print debug message
## usage: `kc_asdf_debug 'this is a %s message' 'debug'`
kc_asdf_debug() {
  kc_asdf_when_debug \
    kc_asdf_log "DBG" "$@"
}

## Print message
## usage: `kc_asdf_printf "test %s" "1"`
kc_asdf_printf() {
  kc_asdf_log '' "$@"
}

## Print start input step in info message
kc_asdf_step_start() {
  local step="$1" format="$2"
  shift 2

  kc_asdf_info "%9s | %-10s | $format" \
    "starting" "$step" "$@"
}

## Print finished input step in info message
kc_asdf_step_success() {
  local step="$1" format="$2"
  shift 2

  kc_asdf_info "%9s | %-10s | $format" \
    "finished" "$step" "$@"
}

## Print help header message
kcs_asdf_help_header() {
  kc_asdf_printf "# %s" "$1"
}

## Print log message with format
## usage: `kc_asdf_log '$KEY' 'this is a %s' 'message'`
## format: '[$KEY] $message'
kc_asdf_log() {
  local key="$1" format="$2"
  shift 2

  [ -n "$key" ] &&
    printf "[%-3s] " "$key" >&2
  # shellcheck disable=SC2059
  printf "$format\n" "$@" >&2
}

## Print error message and exit the program
## usage: `kc_asdf_throw 1 'something went %s' 'wrong'`
kc_asdf_throw() {
  local code="${1:-1}"
  shift

  kc_asdf_error "$@"
  exit "$code"
}

## Execute input command if debug mode enabled
## usage: `kc_asdf_when_debug echo "hello debugger"`
kc_asdf_when_debug() {
  [ -z "${DEBUG:-}" ] &&
    return 0
  "$@"
}

## Execute input command if debug mode disabled
## usage: `kc_asdf_when_not_debug echo "hello normal user"`
kc_asdf_when_not_debug() {
  [ -n "${DEBUG:-}" ] &&
    return 0
  "$@"
}

## Execute input command (if dry-run is disabled)
## usage: `kc_asdf_exec echo 'run'`
## variables:
##   - DRY_RUN | DRYRUN | DRY
kc_asdf_exec() {
  if [ -n "${DRY_RUN:-}" ] ||
    [ -n "${DRYRUN:-}" ] ||
    [ -n "${DRY:-}" ]; then
    kc_asdf_printf "[DRY] %s" "$*"
    return 0
  fi
  "$@"
}

## Fetch redirected location from url
## e.g. `kc_asdf_fetch_location https://google.com`
kc_asdf_fetch_location() {
  local max_redirs=10 tmp_file
  tmp_file="$(kc_asdf_temp_file)"
  export CURL_OPTIONS=(
    --head
    --write-out "%{url_effective}"
    --output "/dev/null"
  )
  export WGET_OPTIONS=(
    --server-response
    --spider
    --output-file "$tmp_file"
  )

  if ! kc_asdf_fetch "$1"; then
    unset CURL_OPTIONS WGET_OPTIONS
    return 11
  elif [ -f "$tmp_file" ]; then
    sed -n -e "s|^[ ]*Location: *||p" <"$tmp_file" |
      tail -n1 &&
      rm "$tmp_file"
  fi

  unset CURL_OPTIONS WGET_OPTIONS
}

## Download file from input url
## e.g. `kc_asdf_fetch_file https://google.com /tmp/index.html`
kc_asdf_fetch_file() {
  local max_redirs=10
  local url="$1" filename="$2"
  export CURL_OPTIONS=(
    --output "$filename"
  )
  export WGET_OPTIONS=(
    --output-file "$filename"
  )

  if ! kc_asdf_fetch "$url"; then
    unset CURL_OPTIONS WGET_OPTIONS
    return 12
  fi
  unset CURL_OPTIONS WGET_OPTIONS
}

## Fetch data from url
## usage: `kc_asdf_fetch https://google.com`
## variables:
##   - CURL_OPTIONS=() for curl options
##   - WGET_OPTIONS=() for wget options
##   - GITHUB_API_TOKEN for authentication
kc_asdf_fetch() {
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

  if [ -n "$cmd" ]; then
    kc_asdf_debug "exec: %s %s %s" \
      "$cmd" "${options[*]}" "$url"
    if ! "$cmd" "${options[@]}" "$url"; then
      kc_asdf_error "fetching %s failed" "$url"
      return 10
    fi
  else
    kc_asdf_error "fetching command not found (e.g. curl, wget)"
    return 10
  fi
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

## Quick helper to throw error if install type is not support
## usage: `kc_asdf_install_not_support "ref"`
## variables:
##   - ASDF_INSTALL_TYPE - set by asdf core
kc_asdf_install_not_support() {
  for t in "$@"; do
    if [[ "$t" == "${ASDF_INSTALL_TYPE:?}" ]]; then
      kc_asdf_throw 7 "your install type (%s) is not supported by plugins" \
        "$t"
    fi
  done
}

## Get current OS name
## usage: `kc_asdf_get_os`
## variable:
##   - ASDF_OVERRIDE_OS for override arch
kc_asdf_get_os() {
  local os="${ASDF_OVERRIDE_OS:-}"
  if [ -n "$os" ]; then
    kc_asdf_info "user overriding OS to '%s'" "$os"
    printf "%s" "$os"
    return 0
  fi

  os="$(uname | tr '[:upper:]' '[:lower:]')"
  case "$os" in
  darwin)
    os="macOS"
    ;;
  linux)
    os="linux"
    ;;
  esac

  printf "%s" "$os"
}

## Get current Arch name
## usage: `kc_asdf_get_arch`
## variable:
##   - ASDF_OVERRIDE_ARCH for override arch
kc_asdf_get_arch() {
  local arch="${ASDF_OVERRIDE_ARCH:-}"
  if [ -n "$arch" ]; then
    kc_asdf_info "user overriding arch to '%s'" "$arch"
    printf "%s" "$arch"
    return 0
  fi

  arch="$(uname -m)"
  case "$arch" in
  aarch64*)
    arch="arm64"
    ;;
  armv5*)
    arch="armv5"
    ;;
  armv6*)
    arch="armv6"
    ;;
  armv7*)
    arch="armv7"
    ;;
  i386)
    arch="386"
    ;;
  i686)
    arch="386"
    ;;
  powerpc64le)
    arch="ppc64le"
    ;;
  ppc64le)
    arch="ppc64le"
    ;;
  x86)
    arch="386"
    ;;
  x86_64)
    arch="amd64"
    ;;
  esac

  printf "%s" "$arch"
}

## Extract compress file
## usage: `kc_asdf_extract /tmp/file.tar.gz /tmp/file`
kc_asdf_extract() {
  local input="$1" output="$2"
  local options=(
    -xzf
    "$input"
    -C "$output"
    --strip-components "1"
  )

  kc_asdf_debug "exec: tar %s" \
    "${options[*]}"
  tar "${options[@]}"
}

## Check shasum of input txt
## usage: `kc_asdf_checksum /tmp/test/checksum.txt`
kc_asdf_checksum() {
  local input="$1"
  local dir file
  dir="$(dirname "$input")"
  file="$(basename "$input")"

  local bit="256"
  local cmd="sha${bit}sum"
  command -v "$cmd" >/dev/null ||
    cmd="shasum"

  kc_asdf_debug "exec: %s --check %s (%s)" \
    "$cmd" "$file" "$dir"

  local tmp="$PWD"
  cd "$dir" ||
    return 1
  "$cmd" --check "$file" >/dev/null ||
    return 1
  cd "$tmp" ||
    return 1
}

## Get latest tags from GitHub
## usage: `kc_asdf_gh_latest`
kc_asdf_gh_latest() {
  local repo="$KC_ASDF_APP_REPO"
  local url="" version=""

  [[ "$repo" =~ ^https://github.com ]] ||
    return 30

  url="$(kc_asdf_fetch_location "$repo/releases/latest")"

  kc_asdf_debug "github latest url: %s" "$url"
  if [ -n "$url" ] && [[ "$url" != "$repo/releases" ]]; then
    version="$(printf "%s\n" "$url" | sed 's|.*/tag/v\{0,1\}||')"
    kc_asdf_debug "use '%s' mode to resolve latest" "github"
  fi

  kc_asdf_debug "latest version is '%s'" "$version"
  if [ -n "$version" ]; then
    printf "%s" "$version"
  else
    return 31
  fi
}

## List all tags from Git
## usage: `output_file="$(kc_asdf_tags_list)"`
kc_asdf_tags_list() {
  local repo="$KC_ASDF_APP_REPO"
  local output
  output="$(kc_asdf_temp_file)"

  kc_asdf_debug "querying all tags from %s" \
    "$repo"
  if git ls-remote --tags --refs "$repo" |
    grep -o 'refs/tags/.*' |
    cut -d/ -f3- >"$output"; then
    printf "%s" "$output"
    return 0
  fi
  kc_asdf_error "cannot list tags from repo (%s)" \
    "$repo"
  return 20
}

## Filter only stable tags from tags list
## usage: `output_file="$(kc_asdf_tags_stable "$input_file")"`
kc_asdf_tags_stable() {
  local input="$1" output
  output="$(kc_asdf_temp_file)"
  local query='(-src|-dev|-latest|-stm|[-\.]rc|-alpha|-beta|[-\.]pre|-next|snapshot|master)'

  kc_asdf_debug "filtering stable tags from %s" \
    "$input"
  if [ -f "$input" ] &&
    grep -ivE "$query" "$input" >"$output"; then
    kc_asdf_when_not_debug rm "$input"
    printf "%s" "$output"
    return 0
  fi
  kc_asdf_error "filter stable tags failed (input=%s)" \
    "$input"
  return 24
}

## Sorting tags using semver
## usage: `output_file="$(kc_asdf_tags_sort "$input_file")"`
kc_asdf_tags_sort() {
  local input="$1" output
  output="$(kc_asdf_temp_file)"

  kc_asdf_debug "sorting tags from %s" \
    "$input"
  if [ -f "$input" ] &&
    sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' "$input" |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}' >"$output"; then
    kc_asdf_when_not_debug rm "$input"
    printf "%s" "$output"
    return 0
  fi
  kc_asdf_error "sort tags failed (input=%s)" \
    "$input"
  return 24
}

## Filter only tag with input regex
## usage: `output_file="$(kc_asdf_tags_only "$input_file" ^v)"`
kc_asdf_tags_only() {
  local input="$1" output
  output="$(kc_asdf_temp_file)"
  local regex="${2:-^\\s*v}"

  kc_asdf_debug "filtering tags with regex '%s' from %s" \
    "$regex" "$input"
  if [ -f "$input" ] &&
    grep -iE "$regex" "$input" >"$output"; then
    kc_asdf_when_not_debug rm "$input"
    printf "%s" "$output"
    return 0
  fi
  kc_asdf_error "filter tags failed (input=%s)" \
    "$input"
  return 24
}

## Formatting tags by remove input regex
## usage: `output_file="$(kc_asdf_tags_format "$input_file" ^v)"`
kc_asdf_tags_format() {
  local input="$1" output
  output="$(kc_asdf_temp_file)"
  local regex="${2:-^\\s*v}"

  kc_asdf_debug "formatting tags with regex '%s' from %s" \
    "$regex" "$input"
  if [ -f "$input" ] &&
    sed "s/$regex//" "$input" >"$output"; then
    kc_asdf_when_not_debug rm "$input"
    printf "%s" "$output"
    return 0
  fi
  kc_asdf_error "format tags failed (input=%s)" \
    "$input"
  return 24
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
