#!/bin/bash
set -euo pipefail
plugin_root="$(cd "$(dirname "$0")/.." && pwd)"
destination="${1:-$HOME/Applications}"
if [[ "$(uname -s)" != Darwin ]]; then echo 'macOS 14 or newer is required.' >&2; exit 1; fi
if [[ -e "$destination/Salary Kkukku.app" ]]; then
  echo 'Salary Kkukku already exists. Installation stopped without replacing it.' >&2
  echo 'Use control.sh launch, or move the old app to Trash before reinstalling. Preferences are retained.' >&2
  exit 1
fi
build_output="$(mktemp -d /private/tmp/salary-kkukku-install.XXXXXX)"
trap 'rm -rf "$build_output"' EXIT
bash "$plugin_root/scripts/build.sh" "$build_output"
mkdir -p "$destination"
ditto --noextattr --norsrc "$build_output/Salary Kkukku.app" "$destination/Salary Kkukku.app"
printf 'Installed: %s\n' "$destination/Salary Kkukku.app"
echo 'Installation did not start the app or change login items.'
