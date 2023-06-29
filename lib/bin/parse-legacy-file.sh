#!/usr/bin/env bash

__asdf_bin() {
  # shellcheck disable=SC2034
  local ns="$1"
  shift

  local filepath="$1"
  if command -v _kc_asdf_custom_parse_version_file >/dev/null; then
    kc_asdf_debug "$ns" "parsing legacy version (%s)" "$filepath"
    _kc_asdf_custom_parse_version_file "$filepath"
  else
    cat "$filepath"
  fi
}
