#!/usr/bin/env bash

## Parse version to major, minor and patch version
## e.g. `read -r major minor patch <<<"$(kc_asdf_version_parser "$version")"`
kc_asdf_version_parser() {
  local version="$1"
  echo "${version//./ }"
}
