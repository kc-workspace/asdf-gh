#!/usr/bin/env bash

## https://asdf-vm.com/plugins/create.html#extension-commands-for-asdf-cli

## Show dev version when version.txt is exist but no content
## Show missing version when version.txt is missing
kc_asdf_main() {
  local plugin_path=""
  plugin_path="$(cd "$(dirname "$0")/../.." && pwd)"

  local version_file="version.txt" version=""
  if [ -f "$plugin_path/$version_file" ]; then
    version="$(cat "$plugin_path/${version_file}")"
    [ -z "$version" ] && version="dev"
  fi

  printf '%s: %s\n' "$(basename "$plugin_path")" "${version:-missing}"
}

kc_asdf_main
