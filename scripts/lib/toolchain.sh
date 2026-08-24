#!/usr/bin/env bash
set -euo pipefail

cletris_root() { cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd; }
cletris_manifest() { printf '%s\n' "$(cletris_root)/environment/toolchain.env"; }
cletris_load_manifest() {
  local line key value
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    key=${line%%=*}; value=${line#*=}
    [[ "$key" != "$line" ]] || { echo "Invalid toolchain manifest line: $line" >&2; return 1; }
    printf -v "$key" '%s' "$value"
    export "$key"
  done < "$(cletris_manifest)"
}
cletris_cache_root() { printf '%s\n' "${CLETRIS_TOOLCHAIN_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/cletris}"; }
cletris_godot() { printf '%s\n' "${CLETRIS_GODOT_BIN:-godot}"; }
cletris_java() { printf '%s\n' "${CLETRIS_JAVA_HOME:+$CLETRIS_JAVA_HOME/bin/java}"; }
cletris_android_sdk() { printf '%s\n' "${CLETRIS_ANDROID_SDK_ROOT:-${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}}"; }
cletris_assert_toolchain() {
  local need_android=${1:-false} godot java sdk found
  cletris_load_manifest
  godot=$(cletris_godot); command -v "$godot" >/dev/null
  found=$("$godot" --version)
  [[ "$found" == "$GODOT_BUILD" ]] || { echo "Godot must be $GODOT_BUILD; found $found" >&2; return 1; }
  java=$(cletris_java); [[ -n "$java" ]] || java=java; command -v "$java" >/dev/null
  "$java" -version 2>&1 | head -1 | grep -Eq 'version "17\.' || { echo 'JDK 17 is required.' >&2; return 1; }
  if [[ "$need_android" == true ]]; then
    sdk=$(cletris_android_sdk); [[ -n "$sdk" && -d "$sdk" ]] || { echo 'Set CLETRIS_ANDROID_SDK_ROOT to the pinned Android SDK.' >&2; return 1; }
    for path in "platform-tools/adb" "build-tools/$ANDROID_BUILD_TOOLS/aapt" "platforms/$ANDROID_PLATFORM/android.jar" "cmdline-tools/latest/bin/sdkmanager" "ndk/$ANDROID_NDK/source.properties" "cmake/$ANDROID_CMAKE/bin/cmake"; do
      [[ -f "$sdk/$path" ]] || { echo "Android SDK missing $path under $sdk" >&2; return 1; }
    done
  fi
}
cletris_enable_godot_isolation() {
  local cache root
  cache=$(cletris_cache_root); root="$(cletris_root)"
  export XDG_CONFIG_HOME="$cache/godot-config"
  export XDG_DATA_HOME="$cache/godot-data"
  export XDG_CACHE_HOME="$cache/godot-cache"
  mkdir -p "$XDG_CONFIG_HOME/godot" "$XDG_DATA_HOME/godot" "$XDG_CACHE_HOME"
  if [[ -n "$(cletris_android_sdk)" && -n "${CLETRIS_JAVA_HOME:-}" ]]; then
    cat > "$XDG_CONFIG_HOME/godot/editor_settings-4.tres" <<EOF
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/java_sdk_path = "${CLETRIS_JAVA_HOME}"
export/android/android_sdk_path = "$(cletris_android_sdk)"
EOF
  fi
}
