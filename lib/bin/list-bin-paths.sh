#!/usr/bin/env bash

__asdf_bin() {
  # shellcheck disable=SC2034
  local ns="$1"
  shift

  local bins=(bin)
  printf "%s" "${bins[*]}"
}
