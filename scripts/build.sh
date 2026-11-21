#!/bin/bash
set -euo pipefail
plugin_root="$(cd "$(dirname "$0")/.." && pwd)"
if [[ "$(uname -s)" != Darwin ]]; then echo 'Kkukku Payday requires macOS 14 or newer.' >&2; exit 1; fi
major="$(sw_vers -productVersion | cut -d. -f1)"
if (( major < 14 )); then echo 'macOS 14 or newer is required.' >&2; exit 1; fi
if ! xcrun --find swiftc >/dev/null 2>&1; then
  echo 'Apple Command Line Tools are required. Install them with xcode-select --install, then retry.' >&2; exit 1
fi
output_dir="${1:-$plugin_root/dist}"
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"
if [[ -e "$output_dir/Kkukku Payday.app" ]]; then echo 'Output app already exists; choose a new build directory.' >&2; exit 1; fi
build_dir="$(mktemp -d /private/tmp/kkukku-payday.XXXXXX)"
trap 'rm -rf "$build_dir"' EXIT
bundle="$build_dir/Kkukku Payday.app"
mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources"
cp "$plugin_root/src/pigeon.png" "$bundle/Contents/Resources/pigeon.png"
cp "$plugin_root/src/Info.plist" "$bundle/Contents/Info.plist"
for arch in arm64 x86_64; do
  xcrun swiftc "$plugin_root/src/SalaryCalculation.swift" "$plugin_root/src/KkukkuPayday.swift" \
    -module-cache-path "$build_dir/module-cache" -framework AppKit -framework SwiftUI \
    -target "$arch-apple-macosx14.0" -o "$build_dir/KkukkuPayday-$arch"
done
lipo -create "$build_dir/KkukkuPayday-arm64" "$build_dir/KkukkuPayday-x86_64" -output "$bundle/Contents/MacOS/KkukkuPayday"
codesign --force --sign - "$bundle"
codesign --verify --strict "$bundle"
ditto --noextattr --norsrc "$bundle" "$output_dir/Kkukku Payday.app"
printf 'Built: %s\n' "$output_dir/Kkukku Payday.app"
