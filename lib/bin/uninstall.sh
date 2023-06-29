#!/usr/bin/env bash

## Default logic
## https://github.com/asdf-vm/asdf/blob/master/lib/commands/command-uninstall.bash
__asdf_bin() {
  # shellcheck disable=SC2034
  local ns="$1"
  shift

  local path="${ASDF_INSTALL_PATH:?}"
  kc_asdf_debug "$ns" "removing '%s' directory" "$path"
  kc_asdf_run rm -rf "$path"
}
