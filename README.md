# Awake#

Small Windows tray utility that toggles **lid close on battery** between:

- **Do nothing** (Καμία ενέργεια)
- **Hibernate** (Αδρανοποίηση)

It is **not** Microsoft PowerToys Awake and does **not** keep the PC awake.

## Install (recommended)

1. Download **`AwakeHash-Setup.exe`** from the [latest release](https://github.com/sun74/awake-hash/releases/latest).
2. Run it and choose whether it should start with Windows.

## Manual install

1. Copy the repo files to a folder (or run from a clone).
2. Run `Install.bat`.

Installed files live in: `%LOCALAPPDATA%\LidToggle\`

## Usage

| Action | Result |
|--------|--------|
| Left-click tray icon | Toggle Do nothing ↔ Hibernate |
| Right-click tray | Pick action, **Start with Windows**, Exit |
| `Ctrl+Alt+L` | One-shot toggle (after install) |

## Requirements

- Windows 10/11 (laptop with lid power options)
- Hibernate available on the device

## Privacy / safety

- No network access
- Changes only the **DC (on battery) lid close** power setting via `powercfg`
- Does not unlock or change other PowerToys settings

## License

MIT
