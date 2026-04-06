#!/usr/bin/env bash
# ToneX Linux Init — uninstaller
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run as root: sudo ./uninstall.sh"
    exit 1
fi

rm -rf /usr/local/lib/tonex-init
rm -f /etc/udev/rules.d/99-tonex.rules
udevadm control --reload-rules

echo "ToneX init uninstalled."
