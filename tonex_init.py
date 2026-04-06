#!/usr/bin/env python3
"""
ToneX USB initialization script.
Replicates the CDC ACM + UAC2 clock setup that Windows driver performs.
"""

import sys
import struct
import usb.core
import usb.util
import time

VENDOR_ID  = 0x1963
PRODUCT_ID = 0x0068
CDC_INTERFACES   = [0, 1]     # CDC Control + CDC Data
AUDIO_INTERFACES = [2, 3, 4, 5, 6]  # AudioControl + AudioStreaming + MIDI

# UAC2 clock: Clock Source ID=7, AudioControl Interface=2
CLOCK_ID    = 7
AC_IFACE    = 2
SAMPLE_RATE = 44100  # ToneX hardware native rate

# UAC2 bRequest codes
GET_CUR = 0x81
SET_CUR = 0x01
GET_RANGE = 0x82

# UAC2 Clock Source control selectors
CS_SAM_FREQ_CONTROL    = 0x01
CS_CLOCK_VALID_CONTROL = 0x02


def find_tonex():
    dev = usb.core.find(idVendor=VENDOR_ID, idProduct=PRODUCT_ID)
    if dev is None:
        print("ERROR: ToneX not found.")
        sys.exit(1)
    print(f"Found: {dev.manufacturer} {dev.product} (s/n {dev.serial_number})")
    return dev


def detach_kernel_drivers(dev, interfaces):
    detached = []
    for iface in interfaces:
        try:
            if dev.is_kernel_driver_active(iface):
                dev.detach_kernel_driver(iface)
                detached.append(iface)
                print(f"Detached kernel driver from interface {iface}")
        except usb.core.USBError as e:
            print(f"Warning: could not detach interface {iface}: {e}")
    return detached


def reattach_kernel_drivers(dev, interfaces):
    for iface in interfaces:
        try:
            dev.attach_kernel_driver(iface)
            print(f"Reattached kernel driver on interface {iface}")
        except usb.core.USBError as e:
            # EBUSY (16): kernel already reclaimed the interface — expected
            # ENOENT (2): UAC2 streaming interface at alt-setting 0 has no driver — expected
            if e.errno not in (2, 16):
                print(f"Warning: could not reattach interface {iface}: {e}")


def set_line_coding(dev):
    line_coding = bytes([
        0x00, 0xC2, 0x01, 0x00,  # dwDTERate = 115200
        0x00,                     # 1 stop bit
        0x00,                     # no parity
        0x08,                     # 8 data bits
    ])
    dev.ctrl_transfer(0x21, 0x20, 0, 0, line_coding)
    print("SET LINE CODING: 115200 8N1 OK")


def set_control_line_state(dev):
    dev.ctrl_transfer(0x21, 0x22, 0x0000, 0, None)
    print("SET CONTROL LINE STATE: DTR=0, RTS=0 OK")


def get_clock_valid(dev):
    wValue = (CS_CLOCK_VALID_CONTROL << 8) | 0x00
    wIndex = (CLOCK_ID << 8) | AC_IFACE
    try:
        result = dev.ctrl_transfer(0xA1, GET_CUR, wValue, wIndex, 1)
        return result[0]
    except usb.core.USBError as e:
        print(f"  Warning: could not read clock valid: {e}")
        return None


def get_sample_rate(dev):
    wValue = (CS_SAM_FREQ_CONTROL << 8) | 0x00
    wIndex = (CLOCK_ID << 8) | AC_IFACE
    try:
        result = dev.ctrl_transfer(0xA1, GET_CUR, wValue, wIndex, 4)
        return struct.unpack('<I', bytes(result))[0]
    except usb.core.USBError as e:
        print(f"  Warning: could not read sample rate: {e}")
        return None


def set_sample_rate(dev, rate):
    wValue = (CS_SAM_FREQ_CONTROL << 8) | 0x00
    wIndex = (CLOCK_ID << 8) | AC_IFACE
    data = struct.pack('<I', rate)
    dev.ctrl_transfer(0x21, SET_CUR, wValue, wIndex, data)
    print(f"SET SAM_FREQ: {rate} Hz OK")


def check_clock(dev):
    valid = get_clock_valid(dev)
    rate  = get_sample_rate(dev)
    print(f"  Clock valid: {valid}  |  Sample rate: {rate} Hz")
    return valid, rate


def main():
    dev = find_tonex()
    detached_cdc   = detach_kernel_drivers(dev, CDC_INTERFACES)
    detached_audio = detach_kernel_drivers(dev, AUDIO_INTERFACES)

    try:
        # 1. CDC init (replicates Windows driver behaviour)
        set_line_coding(dev)
        set_control_line_state(dev)

        # 2. Check clock state before
        print("\nClock state before init:")
        check_clock(dev)

        # 3. Set sample rate
        set_sample_rate(dev, SAMPLE_RATE)
        time.sleep(0.1)

        # 4. Check clock state after
        print("Clock state after SET_SAM_FREQ:")
        valid_after, _ = check_clock(dev)

        if valid_after == 1:
            print("\nClock active — device ready for streaming!")
        else:
            print(f"\nWarning: clock still inactive (valid={valid_after})")

    except usb.core.USBError as e:
        print(f"USB ERROR: {e}")
        sys.exit(1)
    finally:
        reattach_kernel_drivers(dev, detached_cdc)
        reattach_kernel_drivers(dev, detached_audio)
        time.sleep(0.5)


if __name__ == "__main__":
    main()
