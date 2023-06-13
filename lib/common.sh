#!/usr/bin/env bash

## mark script as failed
## e.g. `asdf_fail "cannot found git-tag command"`
asdf_fail() {
  local format="$1"
  shift
  # shellcheck disable=SC2059
  printf "[ERR] %s: $format\n" \
    "$ASDF_PLUGIN_NAME" "$@" >&2
  exit 1
}

## log info message to stderr
## e.g. `asdf_info "found git-tag command"`
asdf_info() {
  local format="$1"
  shift
  # shellcheck disable=SC2059
  printf "[INF] $format\n" "$@" >&2
}

## log debug message to stderr (only if $DEBUG had set)
## e.g. `asdf_debug "found git-tag command"`
asdf_debug() {
  if [ -z "${DEBUG:-}" ]; then
    return 0
  fi

  local format="$1"
  shift
  # shellcheck disable=SC2059
  printf "[DBG] $format\n" "$@" >&2
}

## Sorting version
## e.g. `get_versions | asdf_version_sort`
asdf_version_sort() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

## Filtering only stable version
## e.g. `get_versions | asdf_version_only_stable`
asdf_version_only_stable() {
  local query='(-src|-dev|-latest|-stm|[-\.]rc|-alpha|-beta|[-\.]pre|-next|snapshot|master)'
  grep -ivE "$query"
}

## Format version by remove prefix (default is `v`)
## e.g. `get_versions | asdf_version_format 'v'`
asdf_version_format() {
  local prefix="${1:-v}"
  sed "s/^$prefix//"
}

## Filter input regex from pipe list
## e.g. `get_versions | asdf_version_regex '[0-9]+'`
asdf_version_regex() {
  local query="$1"
  grep -iE "$query"
}

## Filter input version from pipe list
## e.g. `get_versions | asdf_version_only '1.11'`
asdf_version_only() {
  local query="$1"
  grep -iE "^\\s*$query"
}

## List all tags from git repository
## e.g. `asdf_list_git_tags`
asdf_list_git_tags() {
  local repo="$ASDF_PLUGIN_APP_REPO"
  git ls-remote --tags --refs "$repo" |
    grep -o 'refs/tags/.*' |
    cut -d/ -f3-
}

## Print current OS
## e.g. `asdf_get_os`
asdf_get_os() {
  local os="${ASDF_OVERRIDE_OS:-}"
  if [ -n "$os" ]; then
    asdf_info "user overriding OS to '%s'" "$os"
    printf "%s" "$os"
    return 0
  fi

  os="$(uname | tr '[:upper:]' '[:lower:]')"
  case "$os" in
  darwin) os="macOS" ;;
  linux) os="linux" ;;
  esac

  printf "%s" "$os"
}

## Print current arch (support override by $ASDF_OVERRIDE_ARCH)
## e.g. `asdf_get_arch`
asdf_get_arch() {
  local arch="${ASDF_OVERRIDE_ARCH:-}"
  if [ -n "$arch" ]; then
    asdf_info "user overriding ARCH to '%s'" "$arch"
    printf "%s" "$arch"
    return 0
  fi

  arch="$(uname -m)"
  case "$arch" in
  x86_64) arch="amd64" ;;
  x86 | i686 | i386) arch="386" ;;
  powerpc64le | ppc64le) arch="ppc64le" ;;
  armv5*) arch="armv5" ;;
  armv6*) arch="armv6" ;;
  armv7*) arch="arm" ;;
  aarch64) arch="arm64" ;;
  esac

  printf "%s" "$arch"
}

## Install app to input location (support chmod)
asdf_install() {
  local dldir="$1" itdir="$2"
  local file="$ASDF_PLUGIN_APP_NAME"

  local dlpath="$dldir/$file"
  asdf_debug "installing app at %s" "$itdir"

  if [ -d "$dlpath" ]; then
    asdf_debug "moving dir from %s to %s" \
      "$dlpath" "$itdir"
    mv "$dlpath" "$itdir" &&
      asdf_debug "installed dir at %s" "$itdir"
  elif [ -f "$dlpath" ]; then
    local itpath="$itdir/bin"

    mkdir -p "$itpath" 2>/dev/null

    asdf_debug "moving file from %s to %s" \
      "$dlpath" "$itpath"
    mv "$dlpath" "$itpath" &&
      asdf_debug "installed file at %s" "$itpath"
    chmod +x "$itpath/$file"
  else
    asdf_fail "download path not found (%s)" \
      "$dlpath"
  fi

  local name="$ASDF_PLUGIN_APP_NAME"
  local executor="$itdir/bin/$name"
  [ -f "$executor" ] ||
    asdf_fail "command '%s' is missing from '%s'" \
      "$name" "$itdir/bin"
  $executor >/dev/null ||
    asdf_fail "'%s' execute failed"

  asdf_info "finished [%15s] '%s' successfully" \
    "install" "$name"
}

## Download app to input location (should be temp directory)
## e.g. `asdf_download v1.0.1 /tmp/test`
asdf_download() {
  local version="$1" os arch
  os="$(asdf_get_os)"
  arch="$(asdf_get_arch)"

  local download
  download="https://github.com/cli/cli/releases/download/v${version}/gh_${version}_${os}_${arch}.$(asdf_get_download_ext)"
  asdf_info "starting [%15s] %s" \
    "download" "$download"

  local tmpfile="gh_${version}_${os}_${arch}.$(asdf_get_download_ext)"
  local tmpdir
  tmpdir="$(mktemp -d)"
  local tmppath="$tmpdir/$tmpfile"

  asdf_debug "download output %s" \
    "$tmppath"
  asdf_fetch_file "$download" "$tmppath"

  local outdir="$2"
  local outpath="$outdir/$ASDF_PLUGIN_APP_NAME"

  if command -v "asdf_post_download" >/dev/null; then
    asdf_post_download "$tmppath" "$outpath" ||
      asdf_fail "custom post download failed"
  else
    if [[ "$tmppath" =~ \.tar\.gz$ ]] ||
      [[ "$tmppath" =~ \.zip$ ]]; then
      asdf_debug "extracting %s file to %s" \
        "$tmppath" "$outdir"
      asdf_extract_tar "$tmppath" "$outdir" &&
        rm "$tmppath" &&
        asdf_debug "finished [%15s] '%s' successfully" \
          "extract" "$tmpfile"
    else
      asdf_debug "moving app from %s to %s" \
        "$tmppath" "$outpath"
      mv "$tmppath" "$outpath"
    fi
  fi

  local name="$ASDF_PLUGIN_APP_NAME"
  asdf_info "finished [%15s] '%s' successfully" \
    "download" "$name"
}

## url fetch wrapper; CURL_OPTIONS=() for curl options
## e.g. `asdf_fetch https://google.com`
asdf_fetch() {
  local options=()
  local url="$1"
  local token=""

  if [[ "$url" =~ ^https://github.com ]]; then
    token="${GITHUB_API_TOKEN:-}"
    [ -z "$token" ] && token="${GITHUB_TOKEN:-}"
    [ -z "$token" ] && token="${GH_TOKEN:-}"
  fi

  if command -v "curl" >/dev/null; then
    options+=(
      --fail
      --silent
      --show-error
    )

    [ -n "${CURL_OPTIONS:-}" ] &&
      options+=("${CURL_OPTIONS[@]}")

    if [ -n "$token" ]; then
      options+=(
        --header
        "Authorization: token $token"
      )
    fi

    asdf_debug "exec: curl %s %s" \
      "${options[*]}" "$url"
    if ! curl "${options[@]}" "$url"; then
      asdf_fail "fetching %s failed" "$url"
    fi

    return 0
  fi

  asdf_fail "fetch command (e.g. curl) not found"
}

## fetch url and save to file
## e.g. `asdf_fetch_file https://google.com /tmp/output`
asdf_fetch_file() {
  local url="$1"
  export CURL_OPTIONS=(--output "$2" --location)
  asdf_fetch "$url"
  unset CURL_OPTIONS
}

## fetch url header
## e.g. `asdf_fetch_head https://google.com`
asdf_fetch_head() {
  export CURL_OPTIONS=(--head)
  asdf_fetch "$1"
  unset CURL_OPTIONS
}

## Extract contents of tar.gz file
## e.g. `asdf_extract_tar /tmp/test.tar.gz /tmp/test`
asdf_extract_tar() {
  local input="$1" output="$2"
  local options=(
    -xzf
    "$input"
    -C "$output"
    --strip-components=0
  )

  asdf_debug "exec: tar %s" \
    "${options[*]}"
  tar "${options[@]}"
}

## get version marked as latest on Github
## e.g.`asdf_gh_latest`
asdf_gh_latest() {
  local repo="$ASDF_PLUGIN_APP_REPO"
  local url="" version=""
  url="$(
    asdf_fetch_head "$repo/releases/latest" |
      sed -n -e "s|^location: *||p" |
      sed -n -e "s|\r||p"
  )"

  asdf_debug "redirect url: %s" "$url"
  if [ -n "$url" ] && [[ "$url" != "$repo/releases" ]]; then
    version="$(printf "%s\n" "$url" | sed 's|.*/tag/v\{0,1\}||')"
    asdf_debug "use '%s' mode to resolve latest" "github"
  fi

  asdf_debug "latest version is '%s'" "$version"
  [ -n "$version" ] &&
    printf "%s" "$version" ||
    return 1
}
