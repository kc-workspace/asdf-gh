#!/usr/bin/env bash

__asdf_bin() {
  # shellcheck disable=SC2034
  local ns="$1"
  shift

  kc_asdf_help_header "Configuration"
  if command -v _kc_asdf_custom_help >/dev/null; then
    _kc_asdf_custom_help
  else
    echo "no additional config needed"
  fi
}
