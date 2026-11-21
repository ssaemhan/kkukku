#!/bin/bash
set -euo pipefail
plugin_root="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d /private/tmp/salary-kkukku-tests.XXXXXX)"
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc "$plugin_root/src/SalaryCalculation.swift" "$plugin_root/tests/main.swift" -module-cache-path "$test_dir/module-cache" -o "$test_dir/tests"
"$test_dir/tests"
