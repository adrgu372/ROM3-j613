#!/bin/bash
set -euo pipefail

failures=0

section() {
    printf '\n[%s]\n' "$1"
}

need() {
    if "$@"; then
        return 0
    fi
    failures=$((failures + 1))
    return 1
}

section "system"
printf 'kernel: %s\n' "$(uname -r)"
cat /proc/cmdline

section "GPU"
for path in /dev/dri/card0 /dev/dri/card1 /dev/dri/renderD128; do
    if [[ -e $path ]]; then
        printf 'ok      %s\n' "$path"
    else
        printf 'missing %s\n' "$path"
        failures=$((failures + 1))
    fi
done

if [[ -r /sys/class/drm/card1-eDP-1/status ]]; then
    status=$(< /sys/class/drm/card1-eDP-1/status)
    printf 'panel: %s\n' "$status"
    [[ $status == connected ]] || failures=$((failures + 1))
fi

section "device tree"
for property in \
    asahi,t8122-dcp \
    asahi,t8122-gpu \
    asahi,t8122-gpu-power-standin \
    asahi,t8122-gpu-fuse-leakage; do
    path="/sys/firmware/devicetree/base/chosen/$property"
    if [[ -r $path ]] && [[ $(tr -d '\0' < "$path") == 1 ]]; then
        printf 'ok      chosen/%s=1\n' "$property"
    else
        printf 'missing chosen/%s=1\n' "$property"
        failures=$((failures + 1))
    fi
done

section "audio"
cat /proc/asound/cards
audio_state=$(systemctl is-active speakersafetyd || true)
printf 'speakersafetyd: %s\n' "$audio_state"
[[ $audio_state == active ]] || failures=$((failures + 1))

if journalctl -u speakersafetyd -b --no-pager 2>/dev/null |
    grep -q 'Negative power, bad ivsense data'; then
    printf 'error: speakersafetyd reported invalid IV-sense power\n'
    failures=$((failures + 1))
fi

section "renderer"
if command -v glxinfo >/dev/null && [[ -n ${WAYLAND_DISPLAY:-} ]]; then
    glxinfo -B 2>/dev/null | sed -n '/OpenGL renderer/p' || true
fi
if command -v vulkaninfo >/dev/null; then
    vulkaninfo --summary 2>/dev/null | sed -n '/deviceName/p' | head -n 1 || true
fi

if (( failures != 0 )); then
    printf '\nFAILED checks: %d\n' "$failures" >&2
    exit 1
fi

printf '\nAll live-system checks passed.\n'

