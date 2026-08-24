#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
bash "$root/scripts/test.sh"

limit=1048576
budget=26214400
total=0
while IFS= read -r -d '' file; do
  case "$file" in
    .godot/*|.import/*|build/*|drive-builds/*|logs/*|.cache/*|.cletris/*) echo "Tracked generated or delivery path is forbidden: $file" >&2; exit 1 ;;
    *.apk|*.aab|*.keystore|*.jks|*.zip|*.png|*.jpg|*.jpeg|*.webp|*.gif|*.mp3|*.ogg|*.wav|*.ttf|*.otf|*.psd|*.aseprite) echo "Tracked binary/content artifact is forbidden: $file" >&2; exit 1 ;;
  esac
  bytes=$(wc -c < "$root/$file")
  (( bytes <= limit )) || { echo "Tracked file exceeds 1 MiB: $file ($bytes bytes)" >&2; exit 1; }
  (( total += bytes ))
done < <(git -C "$root" ls-files -z)
(( total <= budget )) || { echo "Tracked tree exceeds 25 MiB: $total bytes" >&2; exit 1; }
if [[ -f "$root/.gitattributes" ]] && grep -Eqi 'lfs' "$root/.gitattributes"; then echo 'Git LFS configuration is forbidden.' >&2; exit 1; fi
git -C "$root" diff --check
echo "PASS: tracked tree is $total bytes (budget $budget), no tracked file above 1 MiB."
