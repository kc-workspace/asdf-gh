#!/usr/bin/env bash

## List all tags from Git
## usage: `output_file="$(kc_asdf_tags_list)"`
kc_asdf_tags_list() {
  local ns="tags-list.addon"
  local repo="$KC_ASDF_APP_REPO"
  local output

  if command -v _kc_asdf_custom_tags >/dev/null; then
    output="$(kc_asdf_temp_file)"
    kc_asdf_debug "$ns" "developer custom list of tags"
    _kc_asdf_custom_tags >"$output"
    printf "%s" "$output"
    return 0
  fi

  [ -z "$repo" ] &&
    kc_asdf_error "$ns" "application didn't contains git repo" &&
    return 1

  output="$(kc_asdf_temp_file)"
  kc_asdf_debug "$ns" "querying from %s" "$repo"
  if git ls-remote --tags --refs "$repo" |
    grep -o 'refs/tags/.*' |
    cut -d/ -f3- >"$output"; then
    printf "%s" "$output"
    return 0
  fi

  kc_asdf_error "$ns" "listing failed (%s)" "$repo"
  return 1
}

## Filter only stable tags from tags list
## usage: `output_file="$(kc_asdf_tags_stable "$input_file")"`
kc_asdf_tags_stable() {
  local ns="tags-stable.addon"
  local input="$1" output
  output="$(kc_asdf_temp_file)"
  local query='(-src|-dev|-latest|-stm|[-\.]rc|-alpha|-beta|[-\.]pre|-next|snapshot|master)'

  kc_asdf_debug "$ns" "filtering from %s" "$input"
  if [ -f "$input" ] && grep -ivE "$query" "$input" >"$output"; then
    __asdf_if_not_debug rm "$input"
    printf "%s" "$output"
    return 0
  fi

  kc_asdf_error "$ns" "filtering '%s' failed (%s)" "$query" "$input"
  return 1
}

## Sorting tags using semver
## usage: `output_file="$(kc_asdf_tags_sort "$input_file")"`
kc_asdf_tags_sort() {
  local ns="tags-sort.addon"
  local input="$1" output
  output="$(kc_asdf_temp_file)"

  kc_asdf_debug "$ns" "sorting from %s" "$input"
  if [ -f "$input" ] &&
    sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' "$input" |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}' >"$output"; then
    __asdf_if_not_debug rm "$input"
    printf "%s" "$output"
    return 0
  fi

  kc_asdf_error "$ns" "sorting failed (%s)" "$input"
  return 1
}

## Filter only tag with input regex
## usage: `output_file="$(kc_asdf_tags_only "$input_file" ^v)"`
kc_asdf_tags_only() {
  local ns="tags-only.addon"
  local input="$1" output
  output="$(kc_asdf_temp_file)"
  local regex="${2:-^\\s*v}"

  kc_asdf_debug "$ns" "filtering from %s" "$input"
  if [ -f "$input" ] &&
    grep -iE "$regex" "$input" >"$output"; then
    __asdf_if_not_debug rm "$input"
    printf "%s" "$output"
    return 0
  fi

  kc_asdf_error "$ns" "filtering '%s' failed (%s)" "$regex" "$input"
  return 1
}

## Formatting tags by remove input regex
## usage: `output_file="$(kc_asdf_tags_format "$input_file" ^v)"`
kc_asdf_tags_format() {
  local ns="tags-format.addon"
  local input="$1" output
  output="$(kc_asdf_temp_file)"
  local regex="${2:-^\\s*v}"

  kc_asdf_debug "$ns" "formating from %s" "$input"
  if [ -f "$input" ] &&
    sed "s/$regex//" "$input" >"$output"; then
    __asdf_if_not_debug rm "$input"
    printf "%s" "$output"
    return 0
  fi

  kc_asdf_error "$ns" "formating '%s' failed (%s)" "$regex" "$input"
  return 1
}
