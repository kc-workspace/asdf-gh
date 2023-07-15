#!/usr/bin/env bash

## Extract compress file and move only internal path (if exist)
## usage: `kc_asdf_archive_extract /tmp/file.tar.gz /tmp/file [internal/path]`
kc_asdf_archive_extract() {
  local ns="extract.archive"
  local input="$1" output="$2" internal="$3" tmppath
  local ext="${input##*.}"

  if [ -n "$internal" ]; then
    tmppath="$(kc_asdf_temp_dir)"
  else
    tmppath="$output"
  fi

  if [[ "$ext" == "zip" ]]; then
    kc_asdf_exec unzip -qo "$input" -d "$tmppath" ||
      return 1
  else
    kc_asdf_exec tar -xzf \
      "$input" \
      -C "$tmppath" \
      --strip-components "0" ||
      return 1
  fi

  if [ -n "$internal" ]; then
    kc_asdf_debug "$ns" "found internal directory move from internet instead"
    kc_asdf_transfer "move" "$tmppath/$internal" "$output"
    return $?
  fi
}
