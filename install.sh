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

# 3. Install udev rule
cat > "$UDEV_RULE" << 'EOF'
ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="1963", ATTRS{idProduct}=="0068", RUN+="/usr/local/lib/tonex-init/tonex_udev_init.sh"
EOF

# 4. Reload udev
udevadm control --reload-rules

CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
YELLOW=$'\033[1;33m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
DIM=$'\033[2m'
RESET=$'\033[0m'

W=63
bdr() { printf "${CYAN}${1}${RESET}"; }   # border character(s)
line() {
    local txt="$1"
    local visible
    visible=$(printf '%s' "$txt" | sed 's/\x1b\[[0-9;]*m//g')
    local pad=$(( W - ${#visible} ))
    bdr "│"
    printf " %s%*s " "$txt" "$pad" ""
    bdr "│"
    printf "\n"
}
line_kv() {
    local key="$1" val="$2"
    # between-borders width must equal W+2 (same as separator)
    # 1(space) + 2 + 14(key) + 2 + len(val) + pad + 1(space) = W+2
    local pad=$(( W - 18 - ${#val} ))
    bdr "│"
    printf " ${CYAN}  %-14s${RESET}  %s%*s " "$key" "$val" "$pad" ""
    bdr "│"
    printf "\n"
}
sep() {
    bdr "├"
    printf "${CYAN}"; printf '─%.0s' $(seq 1 $((W+2))); printf "${RESET}"
    bdr "┤"
    printf "\n"
}

echo ""
bdr "┌"; printf "${CYAN}"; printf '─%.0s' $(seq 1 $((W+2))); printf "${RESET}"; bdr "┐"; echo ""
line ""
line "  ${BOLD}${YELLOW}ToneX USB Audio - Linux Init${RESET}"
line ""
sep
line_kv "Install dir  :" "$INSTALL_DIR"
line_kv "udev rule    :" "$UDEV_RULE"
line_kv "Init log     :" "$INSTALL_DIR/logs/"
line_kv "Sample rate  :" "44100 Hz"
sep
line "  ${GREEN}Unplug and replug ToneX - it will initialize automatically.${RESET}"
sep
line "  ${BLUE}${DIM}https://github.com/elroyski/Tonex-Linux-Fix${RESET}"
line ""
bdr "└"; printf "${CYAN}"; printf '─%.0s' $(seq 1 $((W+2))); printf "${RESET}"; bdr "┘"; echo ""
echo ""
