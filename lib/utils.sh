#!/usr/bin/env bash

## User utility functions
## This will load on very beginning of the scripts
## so make sure that you only define functions

download_extension() {
  if [[ "$KC_ASDF_OS" == "macOS" ]]; then
    printf "zip"
  else
    printf "tar.gz"
  fi
}
