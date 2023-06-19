# asdf-gh

This is an asdf-vm plugin generated from [template](template-gh).

## Before start

There are several things template cannot generate for you,
below are a list of thing we should do:

1. make sure that your Github repo already exist at [kc-workspace/asdf-gh][plugin-gh]
2. please read [plugins create section][asdf-create-plugin] for more information
3. remove `before start` section once you completed

## Plugin Consumer

You can use plugin as normal will some extra features.
The below are features supported by template.

### Debug mode

You can enabled debug mode using environment variable called `$DEBUG`.
Set to non-empty string to enable debug mode.

## Plugin Creator

1. All functions and variables should prefix with `kc_asdf_*` or `KC_ASDF_*`
2. All private functions should has `__` prefix (e.g. __kc_asdf_test)
2. `lib/common` and `lib/commands.sh` should not be modify as it might overwrite
3. All `bin/*` script should always has below template

```bash
#!/usr/bin/env bash

## <description>
## https://asdf-vm.com/plugins/create.html

## Your script specific code
# kc_asdf_main() {
#   return 0
# }

## -----------------------------------------------------------------------

set -euo pipefail

export KC_ASDF_PLUGIN_ENTRY_PATH=${BASH_SOURCE[0]}
export KC_ASDF_PLUGIN_ENTRY_NAME
KC_ASDF_PLUGIN_ENTRY_NAME="$(basename "$KC_ASDF_PLUGIN_ENTRY_PATH")"
export KC_ASDF_PLUGIN_PATH
KC_ASDF_PLUGIN_PATH=$(dirname "$(dirname "$KC_ASDF_PLUGIN_ENTRY_PATH")")

# shellcheck source=/dev/null
source "$KC_ASDF_PLUGIN_PATH/lib/commands.sh" "$KC_ASDF_PLUGIN_ENTRY_NAME"
```

<!-- LINKS SECTION -->


[plugin-gh]: https://github.com/kc-workspace/asdf-gh
[template-gh]: https://github.com/kc-workspace/asdf-plugin-template
[asdf-create-plugin]: https://asdf-vm.com/plugins/create.html
