#!/usr/bin/env bash

__asdf_bin() {
  # shellcheck disable=SC2034
  local ns="$1"
  shift

  local type="${ASDF_INSTALL_TYPE:?}"
  local version="${ASDF_INSTALL_VERSION:?}"
  local indir="${ASDF_DOWNLOAD_PATH:?}"
  local outdir="${ASDF_INSTALL_PATH:?}"
  local concurrency="${ASDF_CONCURRENCY:?}"

  kc_asdf_debug "$ns" "installing %s %s %s" \
    "$KC_ASDF_APP_NAME" "$type" "$version"
  kc_asdf_debug "$ns" "download location is %s" "$indir"
  kc_asdf_debug "$ns" "install location is %s" "$outdir"

  if [[ "$type" == "ref" ]]; then
    if command -v _kc_asdf_custom_install_source >/dev/null; then
      _kc_asdf_custom_install_source "$version" \
        "$indir" "$outdir" "$concurrency"
      return $?
    fi

    kc_asdf_error "$ns" "reference mode is not support by current plugin"
    return 1
  fi

  kc_asdf_step "install" "$outdir" \
    kc_asdf_transfer 'copy' "$indir" "$outdir" ||
    return 1## Chmod all bin files
  local bin bins=(bin)
  local file outpath
  for bin in "${bins[@]}"; do
    outpath="$outdir/$bin"
    [ -d "$outpath" ] ||
      continue

    kc_asdf_debug "$ns" "running chmod all files in %s" \
      "$outpath"
    for file in "$outpath"/*; do
      [ -f "$file" ] &&
        kc_asdf_exec chmod +x "$file"
    done
  done

  # shellcheck disable=SC2011
  kc_asdf_debug "$ns" "list '%s': [%s]" \
    "$outdir" "$(ls "$outdir" | xargs echo)"
  for bin in "${bins[@]}"; do
    outpath="$outdir/$bin"
    # shellcheck disable=SC2011
    kc_asdf_debug "$ns" "list '%s': [%s]" \
      "$bin" "$(ls "$outpath" | xargs echo)"
  done
}
