#!/usr/bin/env bash

## Fetch redirected location from url
## e.g. `kc_asdf_fetch_location https://google.com`
kc_asdf_fetch_location() {
  local tmpfile
  tmpfile="$(kc_asdf_temp_file)"
  export CURL_OPTIONS=(
    --head
    --write-out "%{url_effective}"
    --output "/dev/null"
  )
  export WGET_OPTIONS=(
    --server-response
    --spider
    --output-file "$tmpfile"
  )

  if ! kc_asdf_fetch "$1"; then
    unset CURL_OPTIONS WGET_OPTIONS
    return 1
  elif [ -f "$tmpfile" ]; then
    sed -n -e "s|^[ ]*Location: *||p" <"$tmpfile" |
      tail -n1 &&
      rm "$tmpfile"
  fi

  unset CURL_OPTIONS WGET_OPTIONS
}

## Download file from input url
## e.g. `kc_asdf_fetch_file https://google.com /tmp/index.html`
kc_asdf_fetch_file() {
  local url="$1" filename="$2"
  export CURL_OPTIONS=(
    --output "$filename"
  )
  export WGET_OPTIONS=(
    --output-file "$filename"
  )

  if ! kc_asdf_fetch "$url"; then
    unset CURL_OPTIONS WGET_OPTIONS
    return 1
  fi
  unset CURL_OPTIONS WGET_OPTIONS
}

## Fetch data from url
## usage: `kc_asdf_fetch https://google.com`
## variables:
##   - CURL_OPTIONS=() for curl options
##   - WGET_OPTIONS=() for wget options
##   - GITHUB_API_TOKEN for authentication
kc_asdf_fetch() {
  local ns="fetch.defaults"
  local url="$1"
  local cmd="" options=()

  local token=""
  if [[ "$url" =~ ^https://github.com ]] ||
    [[ "$url" =~ ^https://api.github.com ]]; then
    token="${GITHUB_API_TOKEN:-}"
    [ -z "$token" ] && token="${GITHUB_TOKEN:-}"
    [ -z "$token" ] && token="${GH_TOKEN:-}"
  fi

  local max_redirs=10

  if command -v "curl" >/dev/null; then
    cmd="curl"
    options+=(
      --fail
      --silent
      --show-error
      --location
      --max-redirs "$max_redirs"
    )
    [ -n "${CURL_OPTIONS:-}" ] &&
      options+=("${CURL_OPTIONS[@]}")
    [ -n "$token" ] &&
      options+=(--header "Authorization: token $token")
  elif command -v "wget" >/dev/null; then
    cmd="wget"
    options+=(
      --quiet
      --max-redirect "$max_redirs"
    )
    [ -n "${WGET_OPTIONS:-}" ] &&
      options+=("${WGET_OPTIONS[@]}")
    [ -n "$token" ] &&
      options+=(--header "Authorization: token $token")
  fi

  [ -z "$cmd" ] &&
    kc_asdf_error "$ns" "fetch command not found (e.g. curl, wget)" &&
    return 1

  if ! kc_asdf_exec "$cmd" "${options[@]}" "$url"; then
    kc_asdf_error "$ns" "fetching %s failed" "$url"
    return 1
  fi
}
