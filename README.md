# K71M RGB

> **Unofficial.** This is an independent community project. It is not
> affiliated with, endorsed by, or sponsored by i-Rocks. "iRocks" and "K71M"
> are trademarks of their respective owners. This project ships only original
> code and contains no vendor software, binaries, or firmware.

An Omarchy bar widget for the **iRocks K71M** mechanical keyboard
(SONiX SN8F2250 controller, USB `0c45:8075`).

It controls the key backlight and the outer rim directly over the keyboard's
raw HID feature-report protocol — no vendor Windows software and no Wine.

## What it does

- **Keys** — effect dropdown (Static … Shuttle), colour dropdown with presets
  plus a **Custom (r, g, b)** RGB picker, and a brightness slider.
- **Rim** — effect dropdown (Wave … Static), colour dropdown with presets plus
  a custom RGB picker, and a brightness slider.
- **Turn Off** for both zones.
- All **26** effects from the vendor app's list.

## Install

1. Copy this folder to `~/.config/omarchy/plugins/io.github.ryankuo.k71m`.
2. Install the udev rule so your user can reach the keyboard's hidraw node:

   ```bash
   sudo install -m 0644 \
     ~/.config/omarchy/plugins/io.github.ryankuo.k71m/udev/99-k71m.rules \
     /etc/udev/rules.d/99-k71m.rules
   sudo udevadm control --reload-rules
   sudo udevadm trigger --subsystem-match=hidraw
   ```

3. Enable the widget:

   ```bash
   omarchy plugin enable io.github.ryankuo.k71m right
   ```

## CLI

The widget shells out to `bin/k71m_ctrl.py`, which is also usable on its own:

```bash
python3 bin/k71m_ctrl.py set ff8800          # key colour (max brightness)
python3 bin/k71m_ctrl.py set ff8800 8        # key colour at level 8/15
python3 bin/k71m_ctrl.py rim 0000ff          # outer-rim colour
python3 bin/k71m_ctrl.py rim 0000ff 4        # outer-rim colour at level 4/15
python3 bin/k71m_ctrl.py effect breath        # breath|spectrum|ripples|...
python3 bin/k71m_ctrl.py effect rim\ wave     # any of the 26 effect names
python3 bin/k71m_ctrl.py off
python3 bin/k71m_ctrl.py list
```

Effect names: `static`, `singleon`, `singleoff`, `glittering`, `falling`,
`colourful`, `breath`, `spectrum`, `outward`, `scrolling`, `rolling`,
`rotating`, `explode`, `launch`, `ripples`, `flowing`, `pulsating`, `tilt`,
`shuttle`, `rim wave`, `rim aurora`, `rim snake`, `rim spectrum`,
`rim breathing1`, `rim breathing2`, `rim static`.

## How it works

The keyboard exposes a 64-byte HID **feature report** (report id 0) on
interface 0. The vendor app drives lighting by writing a short handshake and
a block of `… aa 55`-terminated frames. A colour frame is 16 bytes: byte 0 is
the "register" (`0x01` = key static colour; for effects the trailing frame
carries the mode, `mode_index + 1`), bytes 1..3 are R,G,B and byte 9 is the
brightness (`level + 1`). The key colour is written through the static block;
the outer rim is the `rim static` effect; the other 25 modes are selected by
their mode byte.

The report stream in `bin/k71m_ctrl.py` was captured from the vendor
application and is replayed verbatim.

## Requirements

- Python 3 (standard library only) and `hidraw` access (the udev rule above).
- Not required: OpenRGB, Wine, the vendor software.
