#!/usr/bin/env bash

## Environment variables
## https://asdf-vm.com/plugins/create.html#environment-variables-overview

ns="commands.lib"

# shellcheck source-path=SCRIPTDIR/utils.sh
source "${KC_ASDF_PLUGIN_PATH:?}/lib/utils.sh"
# shellcheck source-path=SCRIPTDIR/common/index.sh
source "${KC_ASDF_PLUGIN_PATH:?}/lib/common/index.sh"

if command -v _kc_asdf_custom_env >/dev/null; then
  kc_asdf_debug "$ns" "user defined custom environment variables"
  if ! _kc_asdf_custom_env; then
    kc_asdf_warn "$ns" "custom environment return error"
  fi
fi

## This load is optional.
## If load failed, just print error message and continue
__asdf_load "bin" "${KC_ASDF_PLUGIN_ENTRY_NAME//./-}" || printf ''

kc_asdf_debug "$ns" "starting %s with [%s]" \
  "$KC_ASDF_PLUGIN_ENTRY_NAME" "$*"
if command -v kc_asdf_main >/dev/null; then
  kc_asdf_debug "$ns" "use main function instead" \
    "$KC_ASDF_PLUGIN_ENTRY_NAME"
  kc_asdf_main "${KC_ASDF_PLUGIN_ENTRY_NAME}.bin" "$@"
else
  if command -v __asdf_bin >/dev/null; then
    __asdf_bin "${KC_ASDF_PLUGIN_ENTRY_NAME}.bin" "$@"
  else
    kc_asdf_error "bin.internal" \
      "missing default for 'bin/%s', %s is require" \
      "$KC_ASDF_PLUGIN_ENTRY_NAME" "kc_asdf_main()"
    exit 1
  fi
fi

unset ns
