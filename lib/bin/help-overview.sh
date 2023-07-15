#!/usr/bin/env bash

kc_asdf_load_addon "help"

__asdf_bin() {
  # shellcheck disable=SC2034
  local ns="$1"
  shift

  kc_asdf_optional \
    kc_asdf_help_header "$KC_ASDF_NAME"
  if command -v _kc_asdf_custom_help >/dev/null; then
    _kc_asdf_custom_help
  else
    echo "$KC_ASDF_APP_DESC"
    echo
  fi
}
