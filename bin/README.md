# Script bin

> https://asdf-vm.com/plugins/create.html#scripts-overview

## Golden Rules for Plugin Scripts

1. scripts should NOT call other asdf commands
2. keep your dependency list of Shell tools/commands small
3. avoid non-portable tools or command flags. For example, sort -V. See our asdf core list of banned commands

> https://asdf-vm.com/plugins/create.html#golden-rules-for-plugin-scripts

## Generic scripts callback

This listed custom function that can defined on any bin/* scripts.

1. To customize functionality of script (without use any default logic), use `kc_asdf_main()`

```bash
## Example code of kc_asdf_main function
kc_asdf_main() {
  return 0
}
```

## Generic utilities callback

This listed custom function that should defined on **lib/utils.sh**.
To custom some default configuration.

1. To custom final OS name, use `_kc_asdf_custom_os()`

```bash
_kc_asdf_custom_os() {
  local os="$1"
  printf "%s" "$os"
}
```

2. To custom final ARCH name, use `_kc_asdf_custom_arch()`

```bash
_kc_asdf_custom_arch() {
  local arch="$1"
  printf "%s" "$arch"
}
```

## List all callback

1. To filter value from list, use `_kc_asdf_custom_filter()`.

```bash
_kc_asdf_custom_filter() {
  local tmpfile="$1"
  ## Select only version prefix 1
  kc_asdf_tags_only "$tmpfile" "1"
}
```

## Latest stable callback

1. To filter value from list, use `_kc_asdf_custom_filter()`.

```bash
_kc_asdf_custom_filter() {
  local tmpfile="$1" query="$2"
  ## Filter based on user input query
  ## You don't need to as it implemented on default
  kc_asdf_tags_only "$tmpfile" "$query"
}
```

## Download callback

1. To support generate checksum file, use `_kc_asdf_custom_checksum()`

```bash
_kc_asdf_custom_checksum() {
  ## filename is app file to check
  local filename="$1"
  ## checksum_tmp is a raw checksum file from url
  local checksum_tmp="$2"
  ## checksum_path is a output normalize checksum file
  local checksum_path="$3"
}
```

2. To support custom download URL, use `_kc_asdf_custom_download_url()`

```bash
## printf empty string will indicate there are a problem
_kc_asdf_custom_download_url() {
  local version="$1" old_url="$2"
  printf "%s" "$old_url"
}
```

3. To support download source code, use `_kc_asdf_custom_download_source()`

```bash
## This will required _kc_asdf_install_source to defined too
## when `asdf install plugin ref:main`
_kc_asdf_custom_download_source() {
  local version="$1" download_url="$2"
  local download_path="$3"
}
```

4. To support action after downloaded, use `_kc_asdf_custom_post_download()`

```bash
## This won't run on download source code (ref mode)
_kc_asdf_custom_post_download() {
  local version="$1" download_url="$2"
  local tmppath="$3"
}
```

## Install callback

1. To support install from source code, use `_kc_asdf_custom_install_source()`

```bash
## This will required _kc_asdf_download_source to defined too
## when `asdf install plugin ref:main`
_kc_asdf_custom_install_source() {
  local version="$1"
  local download_path="$2" install_path="$3"
  local concurrency="$4"
}
```

## Parse legacy file callback

1. To support parsing legacy version, use `_kc_asdf_custom_parse_version_file()`

```bash
_kc_asdf_custom_parse_version_file() {
  local filepath="$1"
  cat "$filepath"
}
```

## Help overview

1. To override overview message, use `_kc_asdf_custom_help()`

```bash
_kc_asdf_custom_help() {
  printf "this is a override overview help"
}
```

## Help config

1. To override config message, use `_kc_asdf_custom_help()`

```bash
_kc_asdf_custom_help() {
  printf "this is a override config help"
}
```

## Help dependencies

1. To override dependencies message, use `_kc_asdf_custom_help()`

```bash
_kc_asdf_custom_help() {
  local add_deps="$1"
  add_deps "asdf" "curl" "echo"
}
```

## Help links

1. To override links message, use `_kc_asdf_custom_help()`

```bash
_kc_asdf_custom_help() {
  local new_link="$1"
  new_link "Name" "https://example.com"
}
```
