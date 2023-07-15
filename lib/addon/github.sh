#!/usr/bin/env bash

## Get latest tags from GitHub
## usage: `kc_asdf_github_latest`
kc_asdf_github_latest() {
  local ns="gh-latest.addon"
  local repo="${KC_ASDF_APP_REPO:?}"
  local url="" version=""

  [[ "$repo" =~ ^https://github.com ]] ||
    return 1

  url="$(kc_asdf_fetch_location "$repo/releases/latest")"

  kc_asdf_debug "$ns" "fetch latest url: %s" "$url"
  if [ -n "$url" ] && [[ "$url" != "$repo/releases" ]]; then
    version="$(printf "%s\n" "$url" | sed 's|.*/tag/v\{0,1\}||')"
  fi

  kc_asdf_debug "$ns" "latest version is '%s'" "$version"
  [ -n "$version" ] &&
    printf "%s" "$version"
}
