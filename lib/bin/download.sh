#!/usr/bin/env bash

kc_asdf_load_addon "download" "install" \
  "fetch" \
  "system" \
  "checksum" \
  "version" \
  "archive"

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
  command -v _kc_asdf_custom_version >/dev/null &&
    kc_asdf_debug "$ns" "developer defined custom version function" &&
    version="$(_kc_asdf_custom_version "$version")"

  local outdir="${ASDF_DOWNLOAD_PATH:?}" outfile outpath
  local tmpdir tmpfile tmppath
  tmpdir="$(kc_asdf_temp_dir)"
  local vars=("version=$version")
  [ -n "${KC_ASDF_OS:-}" ] && vars+=("os=$KC_ASDF_OS")
  [ -n "${KC_ASDF_ARCH:-}" ] && vars+=("arch=$KC_ASDF_ARCH")
  [ -n "${KC_ASDF_EXT:-}" ] && vars+=("ext=$KC_ASDF_EXT")
  if command -v kc_asdf_version_parser >/dev/null; then
    local major minor patch
    read -r major minor patch <<<"$(kc_asdf_version_parser "$version")"
    vars+=("major_version=$major" "minor_version=$minor" "patch_version=$patch")
  fi
  kc_asdf_debug "$ns" "template variables are '%s'" "${vars[*]}"
  local url mode

  ## If output directory is not empty, mean it cached
  # shellcheck disable=SC2010
  if kc_asdf_present_dir "$outdir"; then
    kc_asdf_debug "$ns" "found download cache at %s" "$outdir"
    if [ -n "${ASDF_FORCE_DOWNLOAD:-}" ]; then
      rm -fr "$outdir" && mkdir "$outdir"
    else
      kc_asdf_info "$ns" \
        "download result has been CACHED, use %s to force redownload" \
        "\$ASDF_FORCE_DOWNLOAD"
      return 0
    fi
  fi

  if kc_asdf_is_ref; then
    kc_asdf_error "$ns" "reference mode is not support by current plugin"
    return 1
  elif kc_asdf_is_ver; then
    url="https://github.com/cli/cli/releases/download/v{version}/gh_{version}_{os}_{arch}.{ext}"
    url="$(kc_asdf_template "$url" "${vars[@]}")"
    command -v _kc_asdf_custom_download_url >/dev/null &&
      kc_asdf_debug "$ns" "developer custom download link" &&
      url="$(_kc_asdf_custom_download_url "$version" "$url")"
  fi
  kc_asdf_debug "$ns" "fetching link is %s" "$url"
  [ -z "$url" ] &&
    kc_asdf_error "cannot download invalid link (%s)" "$url" &&
    return 1

  tmpfile="${url##*/}"
  mode="$(kc_asdf_download_mode "$tmpfile")"
  kc_asdf_debug "$ns" "download mode is %s" "$mode"
  if [[ "$mode" == "git" ]]; then
    kc_asdf_debug "$ns" "cloning '%s' to '%s'" \
      "$url" "$outdir"
    kc_asdf_step "git-clone" "$url" \
      kc_asdf_git_clone "$url" "$outdir" "$version" ||
      return 1
    kc_asdf_debug "$ns" "remove .git directory from download"
    rm -rf "$outdir/.git"
  else
    tmppath="$tmpdir/$tmpfile"
    kc_asdf_step "download" "$url" \
      kc_asdf_fetch_file "$url" "$tmppath" ||
      return 1
    if kc_asdf_enabled_feature checksum; then
      local checksum_url
      checksum_url="https://github.com/cli/cli/releases/download/v{version}/gh_{version}_checksums.txt"
      checksum_url="$(kc_asdf_template "$checksum_url" "${vars[@]}")"
      kc_asdf_step "checksum" "$tmpfile" \
        kc_asdf_checksum "$tmppath" "$checksum_url" ||
        return 1
    fi

    if [[ "$mode" == "file" ]]; then
      outfile="$KC_ASDF_APP_NAME"
      outpath="$outdir/$outfile"
      kc_asdf_step "transfer" "$outpath" \
        kc_asdf_transfer "copy" "$tmppath" "$outpath" ||
        return 1
    elif [[ "$mode" == "archive" ]]; then
      local internal_path
      outpath="$outdir"
      internal_path="gh_{version}_{os}_{arch}"
      [ -n "$internal_path" ] &&
        internal_path="$(kc_asdf_template "$internal_path" "${vars[@]}")"
      kc_asdf_debug "$ns" "extracting '%s' to '%s' (%s)" \
        "$tmppath" "$outpath" "$internal_path"
      kc_asdf_step "extract" "$outpath" \
        kc_asdf_archive_extract "$tmppath" "$outpath" "$internal_path" ||
        return 1
    else
      kc_asdf_error "$ns" "invalid download mode name '%s'" "$mode"
      return 1
    fi
  fi

  __asdf_if_not_debug rm -r "$tmpdir"
  command -v _kc_asdf_custom_post_download >/dev/null &&
    kc_asdf_debug "$ns" "developer has post download source function defined" &&
    _kc_asdf_custom_post_download "$type" "$version" "$outdir"
  # shellcheck disable=SC2011
  kc_asdf_debug "$ns" "list '%s': [%s]" \
    "$outdir" "$(ls "$outdir" | xargs echo)"
}
