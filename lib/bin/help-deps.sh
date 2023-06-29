#!/usr/bin/env bash

__asdf_bin_help_deps_add() {
  for dep in "$@"; do
    echo "$dep"
  done
}

__asdf_bin() {
  # shellcheck disable=SC2034
  local ns="$1"
  shift

  kc_asdf_help_header "Dependencies"
  local deps=(git curl sed grep mktemp xargs tr)

  deps+=(sha256sum shasum)

  for dep in "${deps[@]}"; do
    echo "$dep"
  done

  if command -v _kc_asdf_custom_help >/dev/null; then
    _kc_asdf_custom_help __asdf_bin_help_deps_add
  fi
}
