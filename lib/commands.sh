#!/usr/bin/env bash

## Environment variables
## https://asdf-vm.com/plugins/create.html#environment-variables-overview

## These are set on bin/* scripts
# export ASDF_PLUGIN_SCRIPT="$ASDF_PLUGIN_SCRIPT"
# export ASDF_PLUGIN_PATH="$ASDF_PLUGIN_PATH"
export ASDF_PLUGIN_APP_NAME="gh"
export ASDF_PLUGIN_APP_REPO="https://github.com/cli/cli"
export ASDF_PLUGIN_NAME="asdf-gh"
export ASDF_PLUGIN_REPO="https://github.com/kc-workspace/asdf-gh"

# shellcheck source-path=SCRIPTDIR/common.sh
source "${ASDF_PLUGIN_PATH:?}/lib/common.sh"
# shellcheck source-path=SCRIPTDIR/utils.sh
source "${ASDF_PLUGIN_PATH:?}/lib/utils.sh"

## For bin/latest-stable script
_asdf_query_latest() {
  ## Before asdf send default query instead of empty string
  ## ref: https://github.com/asdf-vm/asdf/blob/5b7d0fea0a10681d89dd7bf4010e0a39e6696841/lib/functions/versions.bash#L136
  local query="$1"

  if [[ "$query" == "[0-9]" ]]; then
    if asdf_gh_latest; then
      return 0
    fi
  fi

  asdf_list_git_tags |
    asdf_version_only 'v' |
    asdf_version_format 'v' |
    asdf_version_only "$query" |
    asdf_version_only_stable |
    asdf_version_sort |
    tail -n1
}
