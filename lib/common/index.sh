#!/usr/bin/env bash## Environment variables
## https://asdf-vm.com/plugins/create.html#environment-variables-overview

# shellcheck source-path=SCRIPTDIR/internal.sh
source "${KC_ASDF_PLUGIN_PATH:?}/lib/common/internal.sh"
# shellcheck source-path=SCRIPTDIR/defaults.sh
source "${KC_ASDF_PLUGIN_PATH:?}/lib/common/defaults.sh"
# shellcheck source-path=SCRIPTDIR/main.sh
source "${KC_ASDF_PLUGIN_PATH:?}/lib/common/main.sh"

## System information
KC_ASDF_OS="$(kc_asdf_get_os)"
KC_ASDF_ARCH="$(kc_asdf_get_arch)"
## Plugin information
KC_ASDF_ORG="kc-workspace"
KC_ASDF_NAME="asdf-gh"
KC_ASDF_REPO="https://github.com/kc-workspace/asdf-gh"
## Application information
KC_ASDF_APP_NAME="gh"
KC_ASDF_APP_DESC=""
KC_ASDF_APP_REPO="https://github.com/cli/cli"

## These are set on bin/* scripts
# export KC_ASDF_PLUGIN_ENTRY_PATH
# export KC_ASDF_PLUGIN_ENTRY_NAME
# export KC_ASDF_PLUGIN_PATH
export KC_ASDF_OS KC_ASDF_ARCH
export KC_ASDF_ORG KC_ASDF_NAME KC_ASDF_REPO
export KC_ASDF_APP_NAME KC_ASDF_APP_DESC KC_ASDF_APP_REPO
