#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT

mkdir -p "$temporary/bin"

cat > "$temporary/bin/pacman" <<'EOF'
#!/bin/bash
set -euo pipefail

case ${1:-} in
    -Sy)
        exit 0
        ;;
    -Qu)
        if [[ -n ${2:-} ]]; then
            grep "^$2 " "$FAKE_QU"
        else
            cat "$FAKE_QU"
        fi
        ;;
    *)
        exit 1
        ;;
esac
EOF
chmod +x "$temporary/bin/pacman"

cat > "$temporary/quarantine" <<'EOF'
linux-rom3
pipewire
EOF

cat > "$temporary/updates" <<'EOF'
linux-rom3 7.3.0.aurora1-45 -> 7.3.0.aurora1-99
pipewire 1:1.6.10-1.2 -> 1:1.6.99-1
firefox 160.0-1 -> 161.0-1
curl 8.23.0-1 -> 8.23.1-1
EOF

cat > "$temporary/pacman.conf" <<'EOF'
[options]
IgnorePkg = kwin

[core]
Server = file:///nonexistent
EOF

cat > "$temporary/override.json" <<'EOF'
{
  "schema_version": 1,
  "distribution": "ROM3-j613",
  "packages": {
    "linux-rom3": "7.3.0.aurora1-99",
    "pipewire": "1:1.6.99-1"
  }
}
EOF

common=(
    env
    "PATH=$temporary/bin:$PATH"
    "FAKE_QU=$temporary/updates"
    "ROM3_QUARANTINE=$temporary/quarantine"
    "ROM3_OVERRIDE_MANIFEST=$temporary/missing-override.json"
    "ROM3_PACMAN_CONF=$temporary/pacman.conf"
)

if unshare -r "${common[@]}" bash "$root/scripts/rom3-j613-update" \
    --check >"$temporary/strict.out" 2>"$temporary/strict.err"; then
    echo "strict mode unexpectedly admitted protected updates" >&2
    exit 1
fi
grep -q 'unqualified updates blocked' "$temporary/strict.err"
grep -qx '  - linux-rom3' "$temporary/strict.err"
grep -qx '  - pipewire' "$temporary/strict.err"

unshare -r "${common[@]}" bash "$root/scripts/rom3-j613-update" \
    --check-safe >"$temporary/safe.out"
grep -q 'protected packages held at their tested versions' "$temporary/safe.out"
grep -q '^firefox 160.0-1 -> 161.0-1$' "$temporary/safe.out"
grep -q '^curl 8.23.0-1 -> 8.23.1-1$' "$temporary/safe.out"
! grep -q '^linux-rom3 .*->' "$temporary/safe.out"
! grep -q '^pipewire .*->' "$temporary/safe.out"

unshare -r "${common[@]}" \
    "ROM3_OVERRIDE_MANIFEST=$temporary/override.json" \
    bash "$root/scripts/rom3-j613-update" \
    --check-approved >"$temporary/approved.out"
grep -q 'linux-rom3 (approved by override: 7.3.0.aurora1-99)' \
    "$temporary/approved.out"
grep -q 'pipewire (approved by override: 1:1.6.99-1)' \
    "$temporary/approved.out"
grep -q '^firefox 160.0-1 -> 161.0-1$' "$temporary/approved.out"

echo "ROM3 safe-update checks passed."
