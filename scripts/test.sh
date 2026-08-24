#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=lib/toolchain.sh
source "$root/scripts/lib/toolchain.sh"
cletris_assert_toolchain false
cletris_enable_godot_isolation
"$(cletris_godot)" --headless --path "$root" --script res://tests/test_rules.gd --quit-after 3
