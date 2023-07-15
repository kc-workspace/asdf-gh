#!/usr/bin/env bash

## Get download mode based on input filename
## usage: `kc_asdf_download_mode 'test.tar.gz'`
## output: git|file|archive|package
kc_asdf_download_mode() {
  local ns="download-mode.addon"
  local filename="$1"
  local mode="file"

  echo "$filename" | grep -qiE "(\.tar\.gz|\.tgz|\.zip)$" &&
    mode="archive"
  echo "$filename" | grep -qiE "\.git$" &&
    mode="git"

  kc_asdf_debug "$ns" "download mode of %s is %s" \
    "$filename" "$mode"
  printf "%s" "$mode"
}
