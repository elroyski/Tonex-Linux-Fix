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
| Sample rate | **44100 Hz** or **48000 Hz** |
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
git clone https://github.com/YOUR_NICK/tonex-init
cd tonex-init
sudo ./install.sh
```

Files are installed to `/usr/local/lib/tonex-init/`.
The udev rule is added to `/etc/udev/rules.d/99-tonex.rules`.

### Uninstall

```bash
sudo ./uninstall.sh
```

---

## Sample rate configuration

The default sample rate is **44100 Hz**. To use **48000 Hz**, set the
`TONEX_SAMPLE_RATE` environment variable in the udev rule or run the init
script manually:

```bash
# Run manually at 48000 Hz
sudo TONEX_SAMPLE_RATE=48000 /usr/local/lib/tonex-init/tonex_udev_init.sh

# Or call the Python script directly
sudo /usr/local/lib/tonex-init/venv/bin/python3 \
    /usr/local/lib/tonex-init/tonex_init.py --rate 48000
```

To make 48000 Hz the permanent default, edit the udev rule:

```bash
sudo nano /etc/udev/rules.d/99-tonex.rules
# Change RUN+="..." to include ENV{TONEX_SAMPLE_RATE}="48000"
```

---

## Test

Unplug and replug the ToneX USB cable, wait 3 seconds:

```bash
# Check the card is visible
aplay -l | grep -i tonex

# Record test (3 seconds) at 44100 Hz
CARD=$(aplay -l | grep -i tonex | grep -oP 'card \K\d+' | head -1)
arecord -D "hw:${CARD},0" -d 3 -f S32_LE -r 44100 -c 2 /tmp/test.wav && aplay /tmp/test.wav

# Record test at 48000 Hz
arecord -D "hw:${CARD},0" -d 3 -f S32_LE -r 48000 -c 2 /tmp/test.wav && aplay /tmp/test.wav
```

---

## Reaper configuration

- Audio system: **JACK** (via PipeWire) or **ALSA**
- Sample rate: **44100 Hz** or **48000 Hz** — must match the rate configured at init
- Buffer: 512 samples (start here, reduce if needed)
- Device (ALSA): `hw:X,0` where X is the card number from `aplay -l`
- Device (JACK/PipeWire): `ToneX Pro`

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

---
---

# ToneX USB Audio — Linux Setup (po polsku)

## Problem

IK Multimedia ToneX Pedal (USB ID `1963:0068`) nie działa jako interfejs audio od razu
po podłączeniu pod Linux. Urządzenie wymaga inicjalizacji portu CDC ACM (serial)
oraz zbindowania interfejsów audio do sterownika `snd-usb-audio`.

Bez inicjalizacji `arecord`/Reaper zgłasza `Input/output error` mimo że karta jest
widoczna w `aplay -l`.

---

## Parametry techniczne urządzenia

| Parametr | Wartość |
|---|---|
| USB Vendor:Product | `1963:0068` |
| Klasa audio | UAC2 (USB Audio Class 2.0) |
| Format | S32_LE (24-bit w 32-bit kontenerze) |
| Sample rate | **44100 Hz** lub **48000 Hz** |
| Kanały | 2 (stereo) |
| CDC baud rate | 115200, 8N1 |

---

## Wymagania

- Linux z kernelem 5.x+ (testowane na 6.17)
- Python 3.8+ z `python3-venv`
- `alsa-utils` (`aplay`, `arecord`)
- PipeWire lub ALSA

```bash
sudo apt install python3 python3-venv alsa-utils   # Debian/Ubuntu
sudo dnf install python3 alsa-utils                # Fedora
```

---

## Instalacja

```bash
git clone https://github.com/TWOJ_NICK/tonex-init
cd tonex-init
sudo ./install.sh
```

Pliki zostaną zainstalowane w `/usr/local/lib/tonex-init/`.
Reguła udev zostanie dodana do `/etc/udev/rules.d/99-tonex.rules`.

### Odinstalowanie

```bash
sudo ./uninstall.sh
```

---

## Konfiguracja sample rate

Domyślna częstotliwość próbkowania to **44100 Hz**. Aby użyć **48000 Hz**, ustaw
zmienną środowiskową `TONEX_SAMPLE_RATE` lub wywołaj skrypt ręcznie:

```bash
# Ręczne uruchomienie z 48000 Hz
sudo TONEX_SAMPLE_RATE=48000 /usr/local/lib/tonex-init/tonex_udev_init.sh

# Lub bezpośrednio przez Python
sudo /usr/local/lib/tonex-init/venv/bin/python3 \
    /usr/local/lib/tonex-init/tonex_init.py --rate 48000
```

Aby ustawić 48000 Hz na stałe, edytuj regułę udev:

```bash
sudo nano /etc/udev/rules.d/99-tonex.rules
# Dodaj ENV{TONEX_SAMPLE_RATE}="48000" do reguły RUN+=
```

---

## Test

Odepnij i podepnij kabel USB Tonexa, poczekaj 3 sekundy:

```bash
# Sprawdź czy karta jest widoczna
aplay -l | grep -i tonex

# Test nagrania (3 sekundy) przy 44100 Hz
CARD=$(aplay -l | grep -i tonex | grep -oP 'card \K\d+' | head -1)
arecord -D "hw:${CARD},0" -d 3 -f S32_LE -r 44100 -c 2 /tmp/test.wav && aplay /tmp/test.wav

# Test nagrania przy 48000 Hz
arecord -D "hw:${CARD},0" -d 3 -f S32_LE -r 48000 -c 2 /tmp/test.wav && aplay /tmp/test.wav
```

---

## Konfiguracja Reapera

- Audio system: **JACK** (przez PipeWire) lub **ALSA**
- Sample rate: **44100 Hz** lub **48000 Hz** — musi zgadzać się z rate ustawionym przy inicjalizacji
- Buffer: 512 samples (zacznij od tego)
- Device (ALSA): `hw:X,0` gdzie X to numer karty z `aplay -l`
- Device (JACK/PipeWire): `ToneX Pro`

---

## Jak to działa

Windows driver przy podłączeniu Tonexa wykonuje sekwencję inicjalizacyjną przez
interfejs CDC ACM (wirtualny port szeregowy `/dev/ttyACM0`):

1. `SET_LINE_CODING` — ustawia port na 115200 baud, 8N1
2. `SET_CONTROL_LINE_STATE` — DTR=0, RTS=0

Bez tej inicjalizacji wewnętrzny zegar audio urządzenia nie konfiguruje się
poprawnie i próba streamowania kończy się błędem `Input/output error`.

Po inicjalizacji CDC skrypt wymusza zbindowanie interfejsów audio (2–6)
do sterownika `snd-usb-audio` przez sysfs.

Skrypt jest wywoływany automatycznie przez `udev` przy każdym podłączeniu.
Log z inicjalizacji: `/usr/local/lib/tonex-init/logs/tonex_udev_init.log`

---

## Diagnostyka

```bash
# Log inicjalizacji
cat /usr/local/lib/tonex-init/logs/tonex_udev_init.log

# Czy kernel widzi urządzenie
lsusb | grep -i tonex

# Czy karta ALSA jest widoczna
aplay -l | grep -i tonex

# Błędy USB
sudo dmesg | grep -i "1963\|tonex" | tail -20

# Ręczna inicjalizacja (bez odpinania)
sudo /usr/local/lib/tonex-init/tonex_udev_init.sh
```
