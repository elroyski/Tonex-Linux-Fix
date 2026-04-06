#!/usr/bin/env bash
# ToneX Linux Init — installer
set -euo pipefail

INSTALL_DIR="/usr/local/lib/tonex-init"
UDEV_RULE="/etc/udev/rules.d/99-tonex.rules"

if [[ $EUID -ne 0 ]]; then
    echo "Run as root: sudo ./install.sh"
    exit 1
fi

echo "Installing ToneX init to $INSTALL_DIR ..."

# 1. Copy files
mkdir -p "$INSTALL_DIR" "$INSTALL_DIR/logs"
cp tonex_init.py "$INSTALL_DIR/"
cp tonex_udev_init.sh "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/tonex_udev_init.sh"

# 2. Create venv and install pyusb
if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3 not found. Install it first: sudo apt install python3 python3-venv"
    exit 1
fi

python3 -m venv "$INSTALL_DIR/venv"
"$INSTALL_DIR/venv/bin/pip" install --quiet pyusb
echo "pyusb installed."

# 3. Install udev rule
cat > "$UDEV_RULE" << 'EOF'
ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="1963", ATTRS{idProduct}=="0068", RUN+="/usr/local/lib/tonex-init/tonex_udev_init.sh"
EOF
echo "udev rule installed: $UDEV_RULE"

# 4. Reload udev
udevadm control --reload-rules
echo "udev rules reloaded."

echo ""
echo "Done. Unplug and replug ToneX — it should initialize automatically."
echo "Init log: $INSTALL_DIR/logs/tonex_udev_init.log"
