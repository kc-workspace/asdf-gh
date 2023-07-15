#!/usr/bin/env bash

## Check is install type is 'ref'
## usage: `kc_asdf_is_ref`
kc_asdf_is_ref() {
  [[ "${ASDF_INSTALL_TYPE:?}" == "ref" ]]
}

## Check is install type is 'version'
## usage: `kc_asdf_is_ver`
kc_asdf_is_ver() {
  [[ "${ASDF_INSTALL_TYPE:?}" == "version" ]]
}
