#!/usr/bin/env python3
"""Userspace RGB control for the iRocks K71M (SONiX SN8F2250).

Talks the keyboard's 64-byte HID feature-report protocol directly through
/dev/hidraw, so neither the vendor Windows software nor Wine is needed.

Commands:
    k71m_ctrl.py list
    k71m_ctrl.py off
    k71m_ctrl.py set RRGGBB [LEVEL]        # key colour, LEVEL 0-15 (default 15)
    k71m_ctrl.py rim RRGGBB [LEVEL]        # outer-rim colour, LEVEL 0-15
    k71m_ctrl.py effect NAME [RRGGBB]      # any of the 26 effects

The report stream was captured from the vendor application and is replayed
verbatim. A colour frame is a 16-byte block ending in 0xaa55 whose first byte
is the "register": 0x01 is the key static colour, and for effects the trailing
frame carries the mode (mode_index + 1). Bytes 1..3 are R,G,B and byte 9 is
the brightness (level + 1).
"""
import fcntl
import glob
import os
import struct
import sys
import time

TARGET_VID = 0x0C45
TARGET_PID = 0x8075

COLORS = {
    "red": (0xFF, 0x00, 0x00), "green": (0x00, 0xFF, 0x00),
    "blue": (0x00, 0x00, 0xFF), "white": (0xFF, 0xFF, 0xFF),
    "magenta": (0xFF, 0x00, 0xFF), "yellow": (0xFF, 0xFF, 0x00),
    "cyan": (0x00, 0xFF, 0xFF), "orange": (0xFF, 0x80, 0x00),
    "purple": (0x80, 0x00, 0xFF), "off": (0x00, 0x00, 0x00),
}

EFFECT_NAMES = [
    "static", "singleon", "singleoff", "glittering", "falling", "colourful",
    "breath", "spectrum", "outward", "scrolling", "rolling", "rotating",
    "explode", "launch", "ripples", "flowing", "pulsating", "tilt",
    "shuttle", "rim wave", "rim aurora", "rim snake", "rim spectrum",
    "rim breathing1", "rim breathing2", "rim static",
]
EFFECT_MODE = {name: i + 1 for i, name in enumerate(EFFECT_NAMES)}
RIM_STATIC_MODE = EFFECT_MODE["rim static"]

_ZERO = "00000000000000000000000000000000"
_FILL = "80000000800000008000000080000000"


def _data_frame(reg, rgb, level=15, flag=0x00):
    return bytes([reg, rgb[0], rgb[1], rgb[2], 0, 0, 0, 0,
                  flag, level + 1, 0x0C, 0, 0, 0, 0xAA, 0x55]).hex()


def _effect_seq(mode_byte, rgb, level=15):
    """Effect/rim sequence: the shared colour block plus the mode frame."""
    block = [
        ("write", _data_frame(0x01, rgb, level)),
        ("write", _data_frame(0x05, (0, 0, 0xFF), 15, flag=0x01)),
        ("write", _data_frame(0x09, (0, 0, 0xFF), 15, flag=0x01)),
        ("write", _data_frame(0x0D, (0, 0, 0xFF), 15, flag=0x01)),
        ("write", _data_frame(0x11, (0, 0, 0xFF), 15, flag=0x01)),
        ("write", _data_frame(0x15, (0, 0, 0xFF), 15)),
        ("write", _data_frame(0x19, (0, 0, 0xFF), 15)),
        ("write", _ZERO),
        ("write", _FILL), ("write", _FILL), ("write", _FILL),
        ("write", _FILL), ("write", _FILL), ("write", _FILL),
        ("write", _FILL), ("write", _FILL), ("write", _FILL),
        ("write", _data_frame(mode_byte, rgb, level, flag=0x01)),
    ]
    return [
        ("write", "04ab0000000000000000000000000000"),
        ("read", "04ab0001000000000000000000000000"),
        ("write", "00000000000000000000000000000000"),
        ("write", "04020000000000000000000000000000"),
        ("read", "04020001008500000000000000000000"),
        ("write", "04130000000000001200000000000000"),
        ("read", "04130001000000001200000000000000"),
    ] + block + [
        ("write", "04020000000000000000000000000000"),
        ("read", "04020001188500000000000000000000"),
        ("write", "04f00000000000000000000000000000"),
    ]


STATIC = [
    ("write", "04050000000000000200000000000000"),
    ("read", "04050001000000000200000000000000"),
    ("read", "40300000450c75801901ffff00000000"),
    ("read", "00000000000000000000000000000000"),
    ("write", "04020000000000000000000000000000"),
    ("read", "04020001ce0300000000000000000000"),
    ("write", "04180000000000000000000000000000"),
    ("read", "04180001000000000000000000000000"),
    ("write", "04180000000000000000000000000000"),
    ("read", "04180001000000000000000000000000"),
    ("write", "04180000000000000000000000000000"),
    ("read", "04180001000000000000000000000000"),
    ("write", "04180000000000000000000000000000"),
    ("read", "04180001000000000000000000000000"),
    ("write", "04190000000000000000000000000000"),
    ("read", "04190001000000000000000000000000"),
    ("write", "04190000000000000000000000000000"),
    ("read", "04190001000000000000000000000000"),
    ("write", "04190000000000000000000000000000"),
    ("read", "04190001000000000000000000000000"),
    ("write", "04ab0000000000000000000000000000"),
    ("read", "04ab0001000000000000000000000000"),
    ("write", "65c9736769b9f62692466e9fc41de584"),
    ("write", "04020000000000000000000000000000"),
    ("read", "040200010dcfe97f0000000000000000"),
    ("write", "04130000000000001200000000000000"),
    ("read", "04130001000000001200000000000000"),
    ("write", "01ff00000000000000100c000000aa55"),
    ("write", "050000ff0000000001100c000000aa55"),
    ("write", "090000ff0000000001100c000000aa55"),
    ("write", "0d0000ff0000000001100c000000aa55"),
    ("write", "110000ff0000000001100c000000aa55"),
    ("write", "150000ff0000000000100c000000aa55"),
    ("write", "190000ff0000000000100c000000aa55"),
    ("write", _ZERO),
    ("write", _FILL), ("write", _FILL), ("write", _FILL),
    ("write", _FILL), ("write", _FILL), ("write", _FILL),
    ("write", _FILL), ("write", _FILL), ("write", _FILL),
    ("write", "01ff00000000000000100c000000aa55"),
    ("write", "04020000000000000000000000000000"),
    ("read", "04020001098500000000000000000000"),
    ("write", "04f00000000000000000000000000000"),
]


def _ioc(direction, typ, nr, size):
    return (direction << 30) | (size << 16) | (ord(typ) << 8) | nr


def find_device():
    for path in sorted(glob.glob("/dev/hidraw*")):
        try:
            fd = os.open(path, os.O_RDWR | os.O_NONBLOCK)
        except OSError:
            continue
        try:
            buf = bytearray(8)
            fcntl.ioctl(fd, _ioc(2, "H", 0x03, 8), buf, True)
            _, vid, pid = struct.unpack("Ihh", buf)
            if (vid & 0xFFFF, pid & 0xFFFF) != (TARGET_VID, TARGET_PID):
                os.close(fd)
                continue
            probe = bytearray(65)
            fcntl.ioctl(fd, _ioc(3, "H", 0x07, 65), probe, True)
            return path, fd
        except OSError:
            os.close(fd)
    raise RuntimeError("K71M (0c45:8075) feature node not found; is the keyboard "
                       "plugged in and the udev rule installed?")


def _set_feature(fd, data):
    buf = bytearray([0x00]) + bytearray(data)
    fcntl.ioctl(fd, _ioc(3, "H", 0x06, len(buf)), buf, True)


def _get_feature(fd):
    buf = bytearray(65)
    fcntl.ioctl(fd, _ioc(3, "H", 0x07, 65), buf, True)
    return bytes(buf)


def run_sequence(template, rgb=None, level=None, patch_static=True, delay=0.003):
    path, fd = find_device()
    try:
        for direction, hexdata in template:
            data = bytearray.fromhex(hexdata)
            colour_frame = len(data) >= 16 and data[14] == 0xAA and data[15] == 0x55
            if colour_frame and (data[0] == 0x01 or not patch_static):
                if rgb is not None:
                    data[1], data[2], data[3] = rgb
                if level is not None:
                    data[9] = max(0, min(15, level)) + 1
            if direction == "write":
                _set_feature(fd, data)
            else:
                _get_feature(fd)
            time.sleep(delay)
    finally:
        os.close(fd)


def parse_color(value):
    value = value.strip().lower().lstrip("#")
    if value in COLORS:
        return COLORS[value]
    if len(value) == 6:
        return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16))
    raise SystemExit(f"unrecognised colour: {value!r}")


def parse_level(args, index):
    if len(args) > index:
        return max(0, min(15, int(args[index])))
    return None


def main():
    args = sys.argv[1:]
    if not args or args[0] in ("-h", "--help"):
        print(__doc__)
        return 0

    if args[0] == "list":
        path, fd = find_device()
        print(path)
        os.close(fd)
        return 0

    if args[0] == "off":
        run_sequence(STATIC, (0, 0, 0), 0)
        run_sequence(_effect_seq(RIM_STATIC_MODE, (0, 0, 0), 0), (0, 0, 0), 0, patch_static=False)
        print("off")
        return 0

    if args[0] == "set" and len(args) >= 2:
        rgb = parse_color(args[1])
        level = parse_level(args, 2)
        run_sequence(STATIC, rgb, level)
        print(f"set {args[1]}" + (f" {args[2]}" if len(args) > 2 else ""))
        return 0

    if args[0] == "rim" and len(args) >= 2:
        rgb = parse_color(args[1])
        level = 15 if len(args) < 3 else parse_level(args, 2)
        run_sequence(_effect_seq(RIM_STATIC_MODE, rgb, level), rgb, level, patch_static=False)
        print(f"rim {args[1]}" + (f" {args[2]}" if len(args) > 2 else ""))
        return 0

    if args[0] == "effect" and len(args) >= 2:
        name = args[1].lower()
        if name not in EFFECT_MODE:
            raise SystemExit(f"unknown effect {name!r}; try: {', '.join(EFFECT_NAMES)}")
        rgb = parse_color(args[2]) if len(args) >= 3 else (0, 0, 0xFF)
        run_sequence(_effect_seq(EFFECT_MODE[name], rgb), rgb, patch_static=False)
        print(f"effect {name}" + (f" {args[2]}" if len(args) >= 3 else ""))
        return 0

    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
