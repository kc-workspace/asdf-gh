#!/usr/bin/env bash

__asdf_bin() {
  # shellcheck disable=SC2034
  local ns="$1"
  shift

  local tmpfile
  tmpfile="$(kc_asdf_tags_list)"
  local filter="^\\s*v"
  tmpfile="$(kc_asdf_tags_only "$tmpfile" "$filter")"
  tmpfile="$(kc_asdf_tags_format "$tmpfile" "$filter")"

  command -v _kc_asdf_custom_filter >/dev/null &&
    tmpfile="$(_kc_asdf_custom_filter "$tmpfile")"
  tmpfile="$(kc_asdf_tags_sort "$tmpfile")"
  kc_asdf_debug "$ns" "final tags read from %s" "$tmpfile" &&
    xargs echo <"$tmpfile" &&
    __asdf_if_not_debug rm "$tmpfile"
}
