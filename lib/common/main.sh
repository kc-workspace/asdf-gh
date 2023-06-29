#!/usr/bin/env bash

## Main function for bin/scripts

## Get current OS name
## usage: `kc_asdf_get_os`
## variable:
##   - ASDF_OVERRIDE_OS for override arch
kc_asdf_get_os() {
  local ns="os.main"
  local os="${ASDF_OVERRIDE_OS:-}"
  if [ -n "$os" ]; then
    kc_asdf_warn "$ns" "user overriding OS to '%s'" "$os"
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

  if command -v _kc_asdf_custom_os >/dev/null; then
    local tmp="$os"
    os="$(_kc_asdf_custom_os "$os")"
    kc_asdf_debug "$ns" "developer has custom OS name from %s to %s" "$tmp" "$os"
  fi

  printf "%s" "$os"
}

## Is current OS is macOS
## usage: `kc_asdf_is_darwin`
kc_asdf_is_darwin() {
  local os="${KC_ASDF_OS}" custom="macOS"
  local darwin="${custom:-darwin}"
  [[ "$os" == "$darwin" ]]
}

## Is current OS is LinuxOS
## usage: `kc_asdf_is_linux`
kc_asdf_is_linux() {
  local os="${KC_ASDF_OS}" custom="linux"
  local linux="${custom:-linux}"
  [[ "$os" == "$linux" ]]
}

## Get current Arch name
## usage: `kc_asdf_get_arch`
## variable:
##   - ASDF_OVERRIDE_ARCH for override arch
kc_asdf_get_arch() {
  local ns="arch.main"
  local arch="${ASDF_OVERRIDE_ARCH:-}"
  if [ -n "$arch" ]; then
    kc_asdf_warn "$ns" "user overriding arch to '%s'" "$arch"
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

  if command -v _kc_asdf_custom_arch >/dev/null; then
    local tmp="$arch"
    arch="$(_kc_asdf_custom_arch "$arch")"
    kc_asdf_debug "$ns" "developer has custom ARCH name from %s to %s" "$tmp" "$arch"
  fi

  printf "%s" "$arch"
}

## Get download mode based on input filename
## usage: `kc_asdf_download_mode 'test.tar.gz'`
## output: file|archive|package
kc_asdf_download_mode() {
  local ns="download-mode.main"
  local filename="$1"
  local mode="file"

  echo "$filename" | grep -qiE "(\.tar\.gz|\.tgz|\.zip)$" &&
    mode="archive"

  

  kc_asdf_debug "$ns" "download mode of %s is %s" \
    "$filename" "$mode"
  printf "%s" "$mode"
}

## Check shasum of input path
## usage: `kc_asdf_checksum '/tmp/hello.tar.gz' 'https://example.com'`
## variables:
##   - ASDF_INSECURE for disable checksum verify
kc_asdf_checksum() {
  local ns="checksum.main"
  local filepath="$1" cs_url="$2"

  [ -n "${ASDF_INSECURE:-}" ] &&
    kc_asdf_warn "$ns" "Skipped checksum because user disable security" &&
    return 0

  local cs_tmp="checksum.tmp" cs_txt="checksum.txt"
  local dirpath filename
  dirpath="$(dirname "$filepath")"
  filename="$(basename "$filepath")"

  local cs_tmppath="$dirpath/$cs_tmp" cs_path="$dirpath/$cs_txt"

  kc_asdf_debug "$ns" "downloading checksum of %s at '%s'" \
    "$filename" "$cs_url"
  if ! kc_asdf_fetch_file "$cs_url" "$cs_tmppath"; then
    return 1
  fi

  kc_asdf_debug "$ns" "modifying checksum '%s' to '%s'" \
    "$cs_tmppath" "$cs_path"
  if command -v _kc_asdf_custom_checksum >/dev/null; then
    kc_asdf_debug "$ns" "use custom function to update checksum file"
    _kc_asdf_custom_checksum "$filename" "$cs_tmppath" "$cs_path"
  else
    if ! grep "$filename" "$cs_tmppath" >"$cs_path"; then
      kc_asdf_error "$ns" "missing %s on checksum file (%s)" \
        "$filename" "$cs_tmppath"
      return 1
    fi
  fi

  local cs_algorithm="256"
  local shasum="sha${cs_algorithm}sum"
  command -v "$shasum" >/dev/null ||
    shasum="shasum"

  local tmp="$PWD"
  cd "$dirpath" &&
    kc_asdf_exec "$shasum" --check "$cs_txt" >/dev/null &&
    cd "$tmp" || return 1
}

## Check GPG value from input path
## usage: `kc_asdf_gpg '/tmp/hello.tar.gz' 'https://example.com'`
kc_asdf_gpg() {
  local ns="gpg.main"
  # TODO: implement gpg verify
  kc_asdf_warn "$ns" "gpg verify is not implemented yet"

  ## Get GPG User ID from public key
  # gpg --list-packets aws.pub | grep -E '^:user ID packet: ' | sed 's|^:user ID packet: ||' | tr -d '"'
  return 0
}

## Get latest tags from GitHub
## usage: `kc_asdf_gh_latest`
kc_asdf_gh_latest() {
  local ns="gh-latest.main"
  local repo="$KC_ASDF_APP_REPO"
  local url="" version=""

  [[ "$repo" =~ ^https://github.com ]] ||
    return 1

  url="$(kc_asdf_fetch_location "$repo/releases/latest")"

  kc_asdf_debug "$ns" "fetch latest url: %s" "$url"
  if [ -n "$url" ] && [[ "$url" != "$repo/releases" ]]; then
    version="$(printf "%s\n" "$url" | sed 's|.*/tag/v\{0,1\}||')"
  fi

  kc_asdf_debug "$ns" "latest version is '%s'" "$version"
  [ -n "$version" ] &&
    printf "%s" "$version"
}

## List all tags from Git
## usage: `output_file="$(kc_asdf_tags_list)"`
kc_asdf_tags_list() {
  local ns="tags-list.main"
  local repo="$KC_ASDF_APP_REPO"
  local output
  output="$(kc_asdf_temp_file)"

  kc_asdf_debug "$ns" "querying from %s" "$repo"
  if git ls-remote --tags --refs "$repo" |
    grep -o 'refs/tags/.*' |
    cut -d/ -f3- >"$output"; then
    printf "%s" "$output"
    return 0
  fi

  kc_asdf_error "$ns" "listing failed (%s)" "$repo"
  return 1
}

## Filter only stable tags from tags list
## usage: `output_file="$(kc_asdf_tags_stable "$input_file")"`
kc_asdf_tags_stable() {
  local ns="tags-stable.main"
  local input="$1" output
  output="$(kc_asdf_temp_file)"
  local query='(-src|-dev|-latest|-stm|[-\.]rc|-alpha|-beta|[-\.]pre|-next|snapshot|master)'

  kc_asdf_debug "$ns" "filtering from %s" "$input"
  if [ -f "$input" ] && grep -ivE "$query" "$input" >"$output"; then
    __asdf_if_not_debug rm "$input"
    printf "%s" "$output"
    return 0
  fi

  kc_asdf_error "$ns" "filtering '%s' failed (%s)" "$query" "$input"
  return 1
}

## Sorting tags using semver
## usage: `output_file="$(kc_asdf_tags_sort "$input_file")"`
kc_asdf_tags_sort() {
  local ns="tags-sort.main"
  local input="$1" output
  output="$(kc_asdf_temp_file)"

  kc_asdf_debug "$ns" "sorting from %s" "$input"
  if [ -f "$input" ] &&
    sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' "$input" |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}' >"$output"; then
    __asdf_if_not_debug rm "$input"
    printf "%s" "$output"
    return 0
  fi

  kc_asdf_error "$ns" "sorting failed (%s)" "$input"
  return 1
}

## Filter only tag with input regex
## usage: `output_file="$(kc_asdf_tags_only "$input_file" ^v)"`
kc_asdf_tags_only() {
  local ns="tags-only.main"
  local input="$1" output
  output="$(kc_asdf_temp_file)"
  local regex="${2:-^\\s*v}"

  kc_asdf_debug "$ns" "filtering from %s" "$input"
  if [ -f "$input" ] &&
    grep -iE "$regex" "$input" >"$output"; then
    __asdf_if_not_debug rm "$input"
    printf "%s" "$output"
    return 0
  fi

  kc_asdf_error "$ns" "filtering '%s' failed (%s)" "$regex" "$input"
  return 1
}

## Formatting tags by remove input regex
## usage: `output_file="$(kc_asdf_tags_format "$input_file" ^v)"`
kc_asdf_tags_format() {
  local ns="tags-format.main"
  local input="$1" output
  output="$(kc_asdf_temp_file)"
  local regex="${2:-^\\s*v}"

  kc_asdf_debug "$ns" "formating from %s" "$input"
  if [ -f "$input" ] &&
    sed "s/$regex//" "$input" >"$output"; then
    __asdf_if_not_debug rm "$input"
    printf "%s" "$output"
    return 0
  fi

  kc_asdf_error "$ns" "formating '%s' failed (%s)" "$regex" "$input"
  return 1
}
