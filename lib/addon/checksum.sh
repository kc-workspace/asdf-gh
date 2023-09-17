#!/usr/bin/env bash

__kc_asdf_checksum_create() {
  if [ "$#" -eq 1 ]; then
    local filename="$1"
    echo "  $1"
  else
    local filename="$1" checksum="$2"
    echo "$checksum  $filename"
  fi
}

## Check shasum of input path
## usage: `kc_asdf_checksum '/tmp/hello.tar.gz' 'https://example.com'`
## variables:
##   - ASDF_INSECURE for disable checksum verify
kc_asdf_checksum() {
  local ns="checksum.addon"
  local filepath="$1" cs_url="$2"

  [ -n "${ASDF_INSECURE:-}" ] &&
    kc_asdf_warn "$ns" "Skipped checksum because user disable security" &&
    return 0

  local cs_tmp="checksum.tmp" cs_txt="checksum.txt"
  local dirpath filename
  dirpath="$(dirname "$filepath")"
  filename="$(basename "$filepath")"

  local cs_tmppath="$dirpath/$cs_tmp" cs_path="$dirpath/$cs_txt"

  kc_asdf_debug "$ns" "downloading checksum of %s from '%s'" \
    "$filename" "$cs_url"
  if ! kc_asdf_fetch_file "$cs_url" "$cs_tmppath"; then
    return 1
  fi

  kc_asdf_debug "$ns" "modifying checksum '%s' to '%s'" \
    "$cs_tmppath" "$cs_path"
  if command -v _kc_asdf_custom_checksum >/dev/null; then
    kc_asdf_debug "$ns" "use custom function to update checksum file"
    _kc_asdf_custom_checksum __kc_asdf_checksum_create \
      "$filename" "$cs_tmppath" >"$cs_path"
  else
    if ! grep -E "$filename$" "$cs_tmppath" >"$cs_path"; then
      kc_asdf_error "$ns" "missing %s on checksum file (%s)" \
        "$filename" "$cs_tmppath"
      return 1
    fi
  fi

  local cs_algorithm="256"
  local shasum="sha${cs_algorithm}sum" args=()
  if ! command -v "$shasum" >/dev/null; then
    shasum="shasum"
    args+=(--algorithm "$cs_algorithm")
  fi
  args+=(--check "$cs_txt")

  local tmp="$PWD"
  cd "$dirpath" &&
    kc_asdf_exec "$shasum" "${args[@]}" >/dev/null &&
    cd "$tmp" || return 1
}
