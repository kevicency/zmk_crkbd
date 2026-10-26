#!/usr/bin/env bash
# Flash one half: scripts/flash.sh left|right [--check]
# --check: exit 0 if firmware/ differs from what was last flashed to that half.
# Builds are reproducible, so the uf2 hash is an exact "needs flashing" test.
set -euo pipefail

side=$1
repo=$(cd "$(dirname "$0")/.." && pwd)
uf2=$(ls "$repo"/firmware/corne_"$side"-*.uf2)
stamp="$repo/firmware/.flashed-$side"
sum=$(shasum -a 256 "$uf2" | cut -d' ' -f1)

if [[ ${2:-} == --check ]]; then
  [[ "$(cat "$stamp" 2>/dev/null)" != "$sum" ]]
  exit
fi

vol=/Volumes/NICENANO
# Both halves mount as NICENANO; a volume present before the prompt belongs to
# some other board (or a half that re-entered its bootloader), never this one.
[[ -d $vol ]] && { echo "$vol already mounted: eject it or reset that board first" >&2; exit 1; }
echo "waiting for $vol: plug in the $side half, double-tap reset"
for _ in $(seq 120); do [[ -d $vol ]] && break; sleep 1; done
[[ -d $vol ]] || { echo "timed out: $vol never mounted" >&2; exit 1; }

# The board reboots mid-copy, so macOS often reports an error on a good flash;
# success is judged by the volume unmounting.
cp -X "$uf2" "$vol/" 2>/dev/null || true
for _ in $(seq 30); do [[ -d $vol ]] || break; sleep 1; done
sleep 3  # an incomplete copy makes the bootloader remount right away
[[ -d $vol ]] && { echo "$vol still mounted: flash failed" >&2; exit 1; }

echo "$sum" > "$stamp"
echo "flashed $side"
