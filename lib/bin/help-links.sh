#!/usr/bin/env bash

kc_asdf_load_addon "help"

__asdf_bin_help_link_printf() {
  local name="${1:?}" url="${2:?}"
  printf "%-12s : %s\n" \
    "$name" "$url"
}

__asdf_bin() {
  # shellcheck disable=SC2034
  local ns="$1"
  shift

  kc_asdf_optional \
    kc_asdf_help_header "Links"
  __asdf_bin_help_link_printf \
    "Website" "$KC_ASDF_APP_WEBS"
  [ -n "$KC_ASDF_APP_REPO" ] && __asdf_bin_help_link_printf \
    "Repository" "$KC_ASDF_APP_REPO"
  __asdf_bin_help_link_printf \
    "Plugin" "$KC_ASDF_REPO"

  kc_asdf_optional \
    _kc_asdf_custom_help __asdf_bin_help_link_printf

  echo
}
