#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=../scripts/lib/toolchain.sh
source "$root/scripts/lib/toolchain.sh"
cletris_load_manifest

args=(
  --build-arg "JDK_DOCKER_IMAGE=$JDK_DOCKER_IMAGE"
  --build-arg "GODOT_RELEASE_TAG=$GODOT_RELEASE_TAG"
  --build-arg "GODOT_BUILD=$GODOT_BUILD"
  --build-arg "GODOT_TEMPLATES_VERSION=$GODOT_TEMPLATES_VERSION"
  --build-arg "GODOT_LINUX_ARCHIVE=$GODOT_LINUX_ARCHIVE"
  --build-arg "GODOT_TEMPLATES_ARCHIVE=$GODOT_TEMPLATES_ARCHIVE"
  --build-arg "ANDROID_COMMAND_LINE_TOOLS=$ANDROID_COMMAND_LINE_TOOLS"
  --build-arg "ANDROID_COMMAND_LINE_TOOLS_LINUX_URL=$ANDROID_COMMAND_LINE_TOOLS_LINUX_URL"
  --build-arg "ANDROID_COMMAND_LINE_TOOLS_LINUX_SHA1=$ANDROID_COMMAND_LINE_TOOLS_LINUX_SHA1"
  --build-arg "ANDROID_PLATFORM=$ANDROID_PLATFORM"
  --build-arg "ANDROID_BUILD_TOOLS=$ANDROID_BUILD_TOOLS"
  --build-arg "ANDROID_NDK=$ANDROID_NDK"
  --build-arg "ANDROID_CMAKE=$ANDROID_CMAKE"
)
docker build --tag "${CLETRIS_DOCKER_TAG:-cletris-dev:4.6}" "${args[@]}" "$root"
