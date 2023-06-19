#!/usr/bin/env bash

## variables:
##   - ASDF_INSECURE - disable checksum check
__asdf_bin_download() {
  kc_asdf_install_not_support "ref"

  local version="${ASDF_INSTALL_VERSION:?}" download
  local tmpl_variables=(
    "os=$KC_ASDF_OS"
    "arch=$KC_ASDF_ARCH"
    "version=$version"
  )
  download="$(
    kc_asdf_template "${KC_ASDF_DOWNLOAD_URL:?}" "${tmpl_variables[@]}"
  )"

  kc_asdf_step_start "download" "'%s' version '%s' (%s)" \
    "$KC_ASDF_APP_NAME" "$version" "$download"

  local tmpdir tmpfile tmppath
  tmpdir="$(kc_asdf_temp_dir)"
  tmpfile="$(
    kc_asdf_template "${KC_ASDF_DOWNLOAD_NAME:?}" "${tmpl_variables[@]}"
  )"
  tmppath="$tmpdir/$tmpfile"

  kc_asdf_debug "download output: %s" "$tmppath"
  kc_asdf_fetch_file "$download" "$tmppath"

  if [ -z "${ASDF_INSECURE:-}" ]; then
    local checksum_tmpfile="checksum.tmp" checksum_file="checksum.txt"
    local checksum_url
    checksum_url="$(
      kc_asdf_template "${KC_ASDF_CHECKSUM_URL:?}" "${tmpl_variables[@]}"
    )"

    kc_asdf_step_start "checksum" "verifying '%s'" \
      "$tmpfile"
    kc_asdf_debug "checksum output: %s" "$tmpdir/$checksum_tmpfile"
    kc_asdf_fetch_file "$checksum_url" "$tmpdir/$checksum_tmpfile"

    if command -v _kc_asdf_custom_checksum >/dev/null; then
      kc_asdf_debug "use custom function to update checksum file"
      _kc_asdf_custom_checksum \
        "$tmpfile" \
        "$tmpdir/$checksum_tmpfile" \
        "$tmpdir/$checksum_file"
    else
      if ! grep "$tmpfile" "$tmpdir/$checksum_tmpfile" >"$tmpdir/$checksum_file"; then
        kc_asdf_throw 9 "cannot found checksum key (%s) from download file" \
          "$tmpfile"
      fi
    fi

    if kc_asdf_checksum "$tmpdir/$checksum_file"; then
      kc_asdf_step_success "checksum" "PASSED"
    else
      kc_asdf_throw 9 "checksum failed, different shasum"
    fi
  else
    kc_asdf_info "you are downloading with insecure mode"
  fi

  local outdir="${ASDF_DOWNLOAD_PATH:?}"
  local outpath

  outpath="$outdir"

  kc_asdf_step_start "extract" "file %s to %s" "$tmpfile" "$outpath"
  if ! kc_asdf_extract "$tmppath" "$outpath"; then
    kc_asdf_throw 8 "cannot extract download file from %s" \
      "$tmppath"
  fi
  kc_asdf_debug "extracted '%s' successfully" "$tmpfile"

  # shellcheck disable=SC2011
  kc_asdf_debug "download directory: [%s]" \
    "$(ls "$outpath" | xargs echo)"
  kc_asdf_when_not_debug rm -r "$tmpdir" &&
    kc_asdf_step_success "download" "successfully"
}

__asdf_bin_install() {
  kc_asdf_install_not_support "ref"

  local version="${ASDF_INSTALL_VERSION:?}" download
  local tmpl_variables=(
    "os=$KC_ASDF_OS"
    "arch=$KC_ASDF_ARCH"
    "version=$version"
  )

  local indir="${ASDF_DOWNLOAD_PATH:?}"
  local outdir="${ASDF_INSTALL_PATH:?}"
  local inpath outpath

  kc_asdf_step_start "install" "'%s' at %s" \
    "$KC_ASDF_APP_NAME" "$outdir"

  kc_asdf_debug "using download='%s' and install='%s' mode" \
    "archive-file" \
    "directory"
  inpath="$indir"
  outpath="$(dirname "$outdir")"

  kc_asdf_debug "moving input (%s) to output (%s)" \
    "$inpath" "$outpath"
  if ! mv "$inpath" "$outpath"; then
    kc_asdf_throw 9 "cannot move directory from %s to %s" \
      "$inpath" "$outpath"
  fi

  outdir="${ASDF_INSTALL_PATH:?}"
  for file in "$outdir"/bin/*; do
    kc_asdf_debug "exec: chmod +x $file"
    chmod +x "$file"
  done

  # shellcheck disable=SC2011
  kc_asdf_debug "install directory: [%s]" \
    "$(ls "$outdir" | xargs echo)"
  # shellcheck disable=SC2011
  kc_asdf_debug "bin directory: [%s]" \
    "$(ls "$outdir/bin" | xargs echo)"
  kc_asdf_step_success "install" "successfully"
}

__asdf_bin_latest-stable() {
  local query="$1" def_query="[0-9]"
  if [[ "$query" == "$def_query" ]]; then
    kc_asdf_debug "try get latest version from github"
    if kc_asdf_gh_latest; then
      return 0
    fi
  fi

  kc_asdf_debug "fallback '%s' mode to resolve latest" "tail"

  local tmp_file filter="^\\s*v"
  tmp_file="$(kc_asdf_tags_list)"
  tmp_file="$(kc_asdf_tags_only "$tmp_file" "$filter")"
  tmp_file="$(kc_asdf_tags_format "$tmp_file" "$filter")"
  tmp_file="$(kc_asdf_tags_only "$tmp_file" "^\\s*$query")"
  command -v _kc_asdf_latest_filter >/dev/null &&
    tmp_file="$(_kc_asdf_latest_filter "$tmp_file" "$query")"
  tmp_file="$(kc_asdf_tags_stable "$tmp_file")"
  tmp_file="$(kc_asdf_tags_sort "$tmp_file")"
  kc_asdf_debug "final tags read from %s" "$tmp_file" &&
    tail -n1 "$tmp_file" &&
    kc_asdf_when_not_debug rm "$tmp_file"
}

__asdf_bin_list-all() {
  local tmp_file filter="^\\s*v"
  tmp_file="$(kc_asdf_tags_list)"
  tmp_file="$(kc_asdf_tags_only "$tmp_file" "$filter")"
  tmp_file="$(kc_asdf_tags_format "$tmp_file" "$filter")"
  command -v _kc_asdf_list_filter >/dev/null &&
    tmp_file="$(_kc_asdf_list_filter "$tmp_file")"
  tmp_file="$(kc_asdf_tags_sort "$tmp_file")"
  kc_asdf_debug "final tags read from %s" "$tmp_file" &&
    xargs echo <"$tmp_file" &&
    kc_asdf_when_not_debug rm "$tmp_file"
}

__asdf_bin_help-overview() {
  kcs_asdf_help_header "$KC_ASDF_NAME"
  kc_asdf_printf "%s" "$KC_ASDF_APP_DESC"
  echo
}

__asdf_bin_help-deps() {
  kcs_asdf_help_header "Dependencies"
  local deps=(git curl sed grep mktemp xargs)
  deps+=(256)
  for dep in "${deps[@]}"; do
    kc_asdf_printf "$dep"
  done
  echo
}

__asdf_bin_help-config() {
  kcs_asdf_help_header "Configuration"
  kc_asdf_printf "no additional config needed"
  echo
}

__asdf_bin_help-links() {
  kcs_asdf_help_header "Links"
  local format="%-12s : %s"
  kc_asdf_printf "$format" \
    "Application" "$KC_ASDF_APP_REPO"
  kc_asdf_printf "$format" \
    "Plugin" "$KC_ASDF_REPO"
}

__asdf_bin_unknown() {
  kc_asdf_error "no default commands default (bin/%s)" "$1"
  kc_asdf_throw 2 "please create kc_asdf_main() function"
}
