#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT

quarantine=$root/packages/rom3-j613-guard/quarantine.packages
update=$root/packages/rom3-j613-guard/rom3-j613-update

run_preflight() {
    local swapfile=$1 swaps=$2 output=$3 error=$4
    unshare -r env \
        ROM3_QUARANTINE="$quarantine" \
        ROM3_SWAPFILE="$swapfile" \
        ROM3_PROC_SWAPS="$swaps" \
        bash "$update" --preflight-apply >"$output" 2>"$error"
}

free_bytes=$(df -B1 --output=avail / | awk 'NR == 2 { print $1 }')
oversized_bytes=$((free_bytes + (2 * 1024 * 1024 * 1024)))
truncate -s "$oversized_bytes" "$temporary/full-swap"
printf 'Filename Type Size Used Priority\n%s file %s 0 -2\n' \
    "$temporary/full-swap" "$((oversized_bytes / 1024))" > "$temporary/full-swaps"
set +e
run_preflight "$temporary/full-swap" "$temporary/full-swaps" \
    "$temporary/full.out" "$temporary/full.err"
status=$?
set -e
[[ $status == 75 ]] || {
    echo "preflight did not return exit 75 for insufficient space" >&2
    exit 1
}
grep -q 'insufficient free space for a safe update' "$temporary/full.err"
grep -q 'Active swapfile:' "$temporary/full.err"
grep -q 'Required free:' "$temporary/full.err"
grep -qi 'no packages were changed' "$temporary/full.err"

: > "$temporary/empty-swap"
printf 'Filename Type Size Used Priority\n%s file 0 0 -2\n' \
    "$temporary/empty-swap" > "$temporary/empty-swaps"
set +e
run_preflight "$temporary/empty-swap" "$temporary/empty-swaps" \
    "$temporary/empty.out" "$temporary/empty.err"
status=$?
set -e
[[ $status == 74 ]] || {
    echo "preflight did not return exit 74 for an empty swapfile" >&2
    exit 1
}
grep -q 'empty or truncated' "$temporary/empty.err"

truncate -s 1M "$temporary/small-swap"
printf 'Filename Type Size Used Priority\n%s file 1024 0 -2\n' \
    "$temporary/small-swap" > "$temporary/small-swaps"
run_preflight "$temporary/small-swap" "$temporary/small-swaps" \
    "$temporary/small.out" "$temporary/small.err"
grep -q 'preflight passed' "$temporary/small.out"

echo "ROM3 update preflight checks passed."
