#!/usr/bin/env bash

## variables:
##   - ASDF_INSECURE - disable checksum check
__asdf_bin() {
  # shellcheck disable=SC2034
  local ns="$1"
  shift

  local type="${ASDF_INSTALL_TYPE:?}"
  local version="${ASDF_INSTALL_VERSION:?}"
  kc_asdf_debug "$ns" "downloading %s %s %s" \
    "$KC_ASDF_APP_NAME" "$type" "$version"

  local vars
  vars=(
    "os=$KC_ASDF_OS"
    "arch=$KC_ASDF_ARCH"
    "version=$version"
  )

  if [[ "$type" == "ref" ]]; then
    if command -v _kc_asdf_custom_download_source >/dev/null; then
      local source_url
      source_url=""
      source_url="$(kc_asdf_template "$source_url" "${vars[@]}")"
      kc_asdf_debug "$ns" "source link is %s" "$source_url"
      [ -z "$source_url" ] &&
        kc_asdf_error "$ns" "invalid source link: %s" \
          "$source_url" &&
        return 1
      _kc_asdf_custom_download_source "$version" "$source_url" "$outdir"
      return $?
    fi

    kc_asdf_error "$ns" "reference mode is not support by current plugin"
    return 1
  fi

  local download_url
  download_url="https://github.com/cli/cli/releases/download/v{version}/gh_{version}_{os}_{arch}.$(download_extension)"
  download_url="$(kc_asdf_template "$download_url" "${vars[@]}")"
  command -v _kc_asdf_custom_download_url >/dev/null &&
    kc_asdf_debug "$ns" "developer custom download link" &&
    download_url="$(_kc_asdf_custom_download_url "$version" "$download_url")"
  kc_asdf_debug "$ns" "download link is %s" "$download_url"
  [ -z "$download_url" ] &&
    kc_asdf_error "invalid download link: %s" "$download_url" &&
    return 1

  local tmpdir tmpfile tmppath
  tmpdir="$(kc_asdf_temp_dir)"
  tmpfile="${download_url##*/}"
  tmppath="$tmpdir/$tmpfile"

  kc_asdf_debug "$ns" "temporary location is %s" "$tmppath"

  kc_asdf_step "download" "$download_url" \
    kc_asdf_fetch_file "$download_url" "$tmppath" ||
    return 1
  command -v _kc_asdf_custom_post_download >/dev/null &&
    kc_asdf_debug "$ns" "developer has post download function defined" &&
    _kc_asdf_custom_post_download "$version" "$download_url" "$tmppath"
  local checksum_url
  checksum_url="https://github.com/cli/cli/releases/download/v{version}/gh_{version}_checksums.txt"
  checksum_url="$(kc_asdf_template "$checksum_url" "${vars[@]}")"
  kc_asdf_step "checksum" "$tmpfile" \
    kc_asdf_checksum "$tmppath" "$checksum_url" ||
    return 1

  local mode
  mode="$(kc_asdf_download_mode "$tmpfile")"
  kc_asdf_debug "$ns" "using '%s' as download mode" "$mode"

  local outfile outdir="${ASDF_DOWNLOAD_PATH:?}" outpath

  if [[ "$mode" == "file" ]]; then
    outfile="$KC_ASDF_APP_NAME"
    outpath="$outdir/$outfile"
    kc_asdf_step "transfer" "$outpath" \
      kc_asdf_transfer "copy" "$tmppath" "$outpath" ||
      return 1
  elif [[ "$mode" == "archive" ]]; then
    outpath="$outdir"

    kc_asdf_debug "$ns" "extracting '%s' to '%s'" \
      "$tmppath" "$outpath"
    kc_asdf_step "extract" "$outpath" \
      kc_asdf_extract "$tmppath" "$outpath" ||
      return 1
  else
    kc_asdf_error "$ns" "invalid download mode name '%s'" "$mode"
    return 1
  fi

  __asdf_if_not_debug rm -r "$tmpdir"
  # shellcheck disable=SC2011
  kc_asdf_debug "$ns" "list '%s': [%s]" \
    "$outdir" "$(ls "$outdir" | xargs echo)"
}
