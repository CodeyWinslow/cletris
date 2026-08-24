#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=lib/toolchain.sh
source "$root/scripts/lib/toolchain.sh"
cletris_assert_toolchain true
cletris_load_manifest
cache=$(cletris_cache_root)
templates="$cache/godot-data/godot/export_templates/$GODOT_TEMPLATES_VERSION"
[[ -d "$templates" ]] || { echo "Isolated export templates are missing. Run scripts/bootstrap.sh --configure first." >&2; exit 1; }
cletris_enable_godot_isolation
"$root/scripts/verify.sh"
mkdir -p "$root/build/android"
output="$root/build/android/Cletris-debug.apk"
"$(cletris_godot)" --headless --path "$root" --export-debug 'Android Debug' "$output"
[[ -f "$output" ]] || { echo "Godot completed without creating expected APK: $output" >&2; exit 1; }
echo "APK exported: $output"
