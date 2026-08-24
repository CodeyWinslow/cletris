#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=lib/toolchain.sh
source "$root/scripts/lib/toolchain.sh"

configure=false
if [[ "${1:-}" == "--configure" ]]; then configure=true; shift; fi
[[ $# -eq 0 ]] || { echo 'Usage: scripts/bootstrap.sh [--configure]' >&2; exit 2; }

cletris_assert_toolchain true
cletris_load_manifest
echo "Repository: $root"
git --version
java_bin=$(cletris_java)
[[ -n "$java_bin" ]] || java_bin=java
"$java_bin" -version 2>&1 | head -1
"$(cletris_godot)" --version
echo "Android SDK: $(cletris_android_sdk)"
echo "Godot isolation cache: $(cletris_cache_root)"

if [[ "$configure" == true ]]; then
  cache=$(cletris_cache_root)
  source_templates="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$GODOT_TEMPLATES_VERSION"
  target_templates="$cache/godot-data/godot/export_templates/$GODOT_TEMPLATES_VERSION"
  if [[ ! -d "$target_templates" ]]; then
    [[ -d "$source_templates" ]] || { echo "Matching export templates are unavailable at $source_templates. Install them, then rerun with --configure." >&2; exit 1; }
    mkdir -p "$(dirname "$target_templates")"
    cp -a "$source_templates" "$target_templates"
  fi
  cletris_enable_godot_isolation
  echo "Configured isolated Godot settings: $XDG_CONFIG_HOME/godot"
  echo "Copied matching export templates: $target_templates"
else
  echo 'Doctor completed. No software, shell profile, or shared Godot setting was modified.'
  echo 'Run scripts/bootstrap.sh --configure once to create isolated Godot settings and copy matching templates.'
fi
