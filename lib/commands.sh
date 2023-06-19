#!/usr/bin/env bash

## Environment variables
## https://asdf-vm.com/plugins/create.html#environment-variables-overview

# shellcheck source-path=SCRIPTDIR/utils.sh
source "${KC_ASDF_PLUGIN_PATH:?}/lib/utils.sh"
# shellcheck source-path=SCRIPTDIR/common/index.sh
source "${KC_ASDF_PLUGIN_PATH:?}/lib/common/index.sh"

kc_asdf_debug "executing '%s' script: arguments [%s]" \
  "$KC_ASDF_PLUGIN_ENTRY_NAME" "$*"

if command -v kc_asdf_main >/dev/null; then
  kc_asdf_debug "use main function on %s script instead" \
    "$KC_ASDF_PLUGIN_ENTRY_NAME"
  kc_asdf_main ||
    kc_asdf_throw 99 "main function failed"
else
  case "${KC_ASDF_PLUGIN_ENTRY_NAME:?}" in
  download) __asdf_bin_download "$@" ;;
  help.config) __asdf_bin_help-config "$@" ;;
  help.deps) __asdf_bin_help-deps "$@" ;;
  help.links) __asdf_bin_help-links "$@" ;;
  help.overview) __asdf_bin_help-overview "$@" ;;
  install) __asdf_bin_install "$@" ;;
  latest-stable) __asdf_bin_latest-stable "$@" ;;
  list-all) __asdf_bin_list-all "$@" ;;
  *) __asdf_bin_unknown "$1" ;;
  esac
fi

unset name args
