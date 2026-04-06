#!/usr/bin/env bash
# ToneX USB initialization — called by udev on device connect
set -euo pipefail

INSTALL_DIR="/usr/local/lib/tonex-init"
PYTHON="$INSTALL_DIR/venv/bin/python3"
SCRIPT="$INSTALL_DIR/tonex_init.py"
LOG_DIR="$INSTALL_DIR/logs"
LOG="$LOG_DIR/tonex_udev_init.log"

# Sample rate: 44100 or 48000. Override via TONEX_SAMPLE_RATE env var.
SAMPLE_RATE="${TONEX_SAMPLE_RATE:-48000}"

mkdir -p "$LOG_DIR"
exec >> "$LOG" 2>&1
echo "--- $(date) --- ToneX udev init start (rate: ${SAMPLE_RATE} Hz)"

# Wait for kernel to finish enumeration
sleep 2

# CDC init + clock setup
"$PYTHON" "$SCRIPT" --rate "$SAMPLE_RATE" || { echo "ERROR: tonex_init.py failed"; exit 1; }

# Find USB sysfs path dynamically
USB_PATH=$(grep -rl "1963" /sys/bus/usb/devices/*/idVendor 2>/dev/null \
    | head -1 | xargs dirname | xargs basename 2>/dev/null || true)

if [[ -z "$USB_PATH" ]]; then
    echo "ERROR: could not find sysfs path for ToneX"
    exit 1
fi

echo "USB path: $USB_PATH"

# Bind audio interfaces to snd-usb-audio
for i in 2 3 4 5 6; do
    IFACE="${USB_PATH}:1.${i}"
    if [[ ! -e "/sys/bus/usb/drivers/snd-usb-audio/${IFACE}" ]]; then
        echo "$IFACE" > /sys/bus/usb/drivers/snd-usb-audio/bind 2>/dev/null \
            && echo "Bound $IFACE" \
            || echo "Skipped $IFACE"
    else
        echo "Already bound: $IFACE"
    fi
done

echo "ToneX init complete."
