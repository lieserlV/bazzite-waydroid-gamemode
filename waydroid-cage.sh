#!/bin/bash
# 파일명: $HOME/bin/waydroid-cage.sh

set -euo pipefail

# -------------------------------
# 1. Waydroid 설치 확인
# -------------------------------
if ! command -v waydroid >/dev/null 2>&1; then
    echo "❌ Waydroid is not installed. Please install it first."
    exit 1
fi

# -------------------------------
# 2. 화면 해상도 감지
# -------------------------------
RESOLUTION=""
if command -v xrandr >/dev/null 2>&1; then
    RESOLUTION=$(xrandr 2>/dev/null | awk '/\*/ {print $1; exit}')
fi

if [[ -z "${RESOLUTION}" ]] && command -v xdpyinfo >/dev/null 2>&1; then
    RESOLUTION=$(xdpyinfo 2>/dev/null | awk '/dimensions/{print $2; exit}')
fi

if [[ -z "${RESOLUTION}" ]]; then
    RESOLUTION="1920x1080"
fi

# -------------------------------
# 3. Waydroid 컨테이너 시작
# -------------------------------
if command -v systemctl >/dev/null 2>&1; then
    if systemctl --user list-unit-files 2>/dev/null | grep -q '^waydroid-container\.service'; then
        systemctl --user start waydroid-container.service
        SYSTEMCTL_CMD=(systemctl --user)
    else
        sudo systemctl start waydroid-container.service
        SYSTEMCTL_CMD=(systemctl)
    fi
else
    echo "❌ systemctl is not available."
    exit 1
fi

if ! "${SYSTEMCTL_CMD[@]}" is-active --quiet waydroid-container.service; then
    echo "❌ Waydroid container failed to start."
    exit 1
fi

# -------------------------------
# 4. Kernel pid_max 설정
# -------------------------------
CACHE_FILE="$HOME/.cache/orig_kernel.pid_max"
mkdir -p "$(dirname "$CACHE_FILE")"
CURRENT_PID_MAX=$(sysctl -n kernel.pid_max 2>/dev/null || true)
if [[ -n "${CURRENT_PID_MAX}" ]]; then
    printf '%s\n' "$CURRENT_PID_MAX" > "$CACHE_FILE"
    sudo sysctl -w kernel.pid_max=65535 >/dev/null
fi

cleanup() {
    if [[ -f "$CACHE_FILE" ]]; then
        sudo sysctl -w kernel.pid_max="$(cat "$CACHE_FILE")" >/dev/null || true
        rm -f "$CACHE_FILE"
    fi

    if [[ "${SYSTEMCTL_CMD[*]}" == "systemctl --user" ]]; then
        systemctl --user stop waydroid-container.service >/dev/null 2>&1 || true
    else
        sudo systemctl stop waydroid-container.service >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

# -------------------------------
# 5. Android 부팅 대기
# -------------------------------
while [[ -z $(waydroid shell getprop sys.boot_completed 2>/dev/null) ]]; do
    sleep 1
done

# -------------------------------
# 6. Cage 실행
# -------------------------------
if ! command -v cage >/dev/null 2>&1; then
    echo "❌ cage is not installed. Please install it first."
    exit 1
fi

if ! command -v wlr-randr >/dev/null 2>&1; then
    echo "❌ wlr-randr is not installed. Please install it first."
    exit 1
fi

WAYDROID_CMD='waydroid show-full-ui'
if [[ -n "${1:-}" ]]; then
    WAYDROID_CMD=$(printf 'waydroid session start && sleep 1 && waydroid app launch "%s" && sleep 1 && waydroid show-full-ui' "$1")
fi

echo "🌿 Running in Wayland-compatible session"
cage -- bash -lc "
    if command -v wlr-randr >/dev/null 2>&1; then
        monitor=\$(wlr-randr 2>/dev/null | awk '/ connected/{print \$1; exit}')
        if [[ -n \"\$monitor\" ]]; then
            wlr-randr --output \"\$monitor\" --custom-mode \"$RESOLUTION\" || true
        fi
    fi
    $WAYDROID_CMD
"
