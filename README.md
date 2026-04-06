# ToneX USB Audio — Linux Setup

## Problem

The IK Multimedia ToneX Pedal (USB ID `1963:0068`) does not work as an audio
interface immediately after plugging into Linux. The device requires initialization
of its CDC ACM (serial) port and rebinding of audio interfaces to the
`snd-usb-audio` driver.

Without initialization, `arecord`/Reaper reports `Input/output error` even though
the card appears in `aplay -l`.

---

## Device Technical Specs

| Parameter | Value |
|---|---|
| USB Vendor:Product | `1963:0068` |
| Audio class | UAC2 (USB Audio Class 2.0) |
| Format | S32_LE (24-bit in 32-bit container) |
| Sample rate | **44100 Hz** |
| Channels | 2 (stereo) |
| CDC baud rate | 115200, 8N1 |

---

## Requirements

- Linux kernel 5.x+ (tested on 6.17)
- Python 3.8+ with `python3-venv`
- `alsa-utils` (`aplay`, `arecord`)
- PipeWire or ALSA

```bash
sudo apt install python3 python3-venv alsa-utils   # Debian/Ubuntu
sudo dnf install python3 alsa-utils                # Fedora
```

---

## Installation

```bash
git clone https://github.com/elroyski/Tonex-Linux-Fix
cd Tonex-Linux-Fix
sudo ./install.sh
```

Files are installed to `/usr/local/lib/tonex-init/`.
The udev rule is added to `/etc/udev/rules.d/99-tonex.rules`.

### Uninstall

```bash
sudo ./uninstall.sh
```

---

## Test

Unplug and replug the ToneX USB cable, wait 3 seconds:

```bash
# Check the card is visible
aplay -l | grep -i tonex

# Record test (3 seconds)
CARD=$(aplay -l | grep -i tonex | grep -oP 'card \K\d+' | head -1)
arecord -D "hw:${CARD},0" -d 3 -f S32_LE -r 44100 -c 2 /tmp/test.wav && aplay /tmp/test.wav
```

---

## Reaper configuration

- Audio system: **ALSA**
- Sample rate: **44100 Hz**
- Buffer: 512 samples (start here, reduce if needed)
- Device: `hw:ToneX ; USB-Audio - ToneX`

---

## How it works

The Windows driver performs an initialization sequence over the CDC ACM interface
(virtual serial port `/dev/ttyACM0`) when ToneX is plugged in:

1. `SET_LINE_CODING` — configures the port to 115200 baud, 8N1
2. `SET_CONTROL_LINE_STATE` — DTR=0, RTS=0 (port open, signals inactive)

Without this initialization the device's internal audio clock does not configure
correctly, causing streaming to fail with `Input/output error`.

After the CDC init, the script forces rebinding of audio interfaces (2–6) to
`snd-usb-audio` via sysfs.

The script is called automatically by `udev` every time the device is connected.
Initialization log: `/usr/local/lib/tonex-init/logs/tonex_udev_init.log`

---

## Troubleshooting

```bash
# Initialization log
cat /usr/local/lib/tonex-init/logs/tonex_udev_init.log

# Check kernel sees the device
lsusb | grep -i tonex

# Check ALSA card is visible
aplay -l | grep -i tonex

# USB errors
sudo dmesg | grep -i "1963\|tonex" | tail -20

# Run initialization manually (without replug)
sudo /usr/local/lib/tonex-init/tonex_udev_init.sh
```
