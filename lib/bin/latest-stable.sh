#!/usr/bin/env bash

kc_asdf_load_addon "fetch"
kc_asdf_load_addon "github"
kc_asdf_load_addon "tags"

__asdf_bin() {
  # shellcheck disable=SC2034
  local ns="$1"
  shift

  local query="$1" def_query="[0-9]"
  if [[ "$query" == "$def_query" ]]; then
    command -v kc_asdf_github_latest >/dev/null &&
      kc_asdf_debug "$ns" "try get latest version from github" &&
      kc_asdf_github_latest &&
      return 0
  fi

  kc_asdf_debug "$ns" "fallback '%s' mode to resolve latest" "tail"

  local tmpfile filter="^\\s*v"
  tmpfile="$(kc_asdf_tags_list)"
  tmpfile="$(kc_asdf_tags_only "$tmpfile" "$filter")"
  tmpfile="$(kc_asdf_tags_format "$tmpfile" "$filter")"
  tmpfile="$(kc_asdf_tags_only "$tmpfile" "^\\s*$query")"
  command -v _kc_asdf_custom_filter >/dev/null &&
    tmpfile="$(_kc_asdf_custom_filter "$tmpfile" "$query")"
  tmpfile="$(kc_asdf_tags_stable "$tmpfile")"
  tmpfile="$(kc_asdf_tags_sort "$tmpfile")"
  kc_asdf_debug "$ns" "final tags read from %s" "$tmpfile" &&
    tail -n1 "$tmpfile" &&
    __asdf_if_not_debug rm "$tmpfile"
}
