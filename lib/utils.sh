#!/usr/bin/env bash

asdf_get_download_ext() {
  local os=""
  os="$(asdf_get_os)"

  if [[ "$os" == "macOS" ]]; then
    printf "zip"
  else
    printf "tar.gz"
  fi
}
