# HITMAN Co-op — Artur Edition Steam Deck / Proton installation guide

This document describes the separate Steam Deck compatibility package for the existing Windows Artur Edition multiplayer mod.

## What this package is

This is not a native Linux port. It is a Steam Deck compatibility wrapper that installs the existing Windows Artur Edition files into the installed HITMAN World of Assassination directory and launches the game through Steam using Proton.

It intentionally preserves the existing Windows multiplayer system and protocol compatibility, rather than creating a separate multiplayer engine.

## Important limits

This package is experimental and still requires real Steam Deck testing.

- The Windows Artur Edition runtime remains the authoritative implementation.
- Steam friend invitations and P2P behaviour depend on Steam + Proton compatibility.
- The package does not claim validated multiplayer gameplay unless tested on real hardware.

## Required versions

- HITMAN World of Assassination
- Steam App ID: `1659040`
- Required game version: `3.290.1.0`
- Required SDK: `ZHMModSDK 4.2.1`
- Multiplayer protocol: `16`

## Install in Desktop Mode

1. Copy the `steamdeck/` directory to a place you can access from Steam Deck Desktop Mode.
2. Open a terminal in Desktop Mode.
3. Detect the game automatically:

```bash
bash steamdeck/install.sh
```

4. If the game is not found automatically, pass the path explicitly:

```bash
bash steamdeck/install.sh --game "/path/to/HITMAN World of Assassination"
```

5. If you have the extracted Artur Edition bundle available locally, pass it explicitly:

```bash
bash steamdeck/install.sh --game "/path/to/HITMAN World of Assassination" --package "/path/to/Artur-Release"
```

## Launch through Steam

```bash
bash steamdeck/launch.sh
```

The launcher prefers the official Steam entry point and uses App ID `1659040`.

## Verify installation

```bash
bash steamdeck/verify.sh --game "/path/to/HITMAN World of Assassination"
```

## Repair or restore

```bash
bash steamdeck/restore.sh --game "/path/to/HITMAN World of Assassination"
```

```bash
bash steamdeck/uninstall.sh --game "/path/to/HITMAN World of Assassination"
```

## Common troubleshooting

### Game not detected

- Ensure HITMAN is installed through Steam.
- Check the Steam library and custom library locations.
- Pass `--game` explicitly.

### Artur Edition files not detected

- Ensure the package contains the expected nested `Retail` layout.
- Use the extracted release folder rather than a random ZIP root directory.
- Confirm the package contains at least the required Artur files.

### Steam launcher does not start the game

- Check that the App ID is `1659040`.
- Verify Steam is installed and working in Desktop Mode.
- Use the direct Proton fallback only for troubleshooting:

```bash
bash steamdeck/launch.sh --force-direct
```

## Compatibility and risk caveat

This entire package is an experimental wrapper around the Windows Artur Edition installation. It does not guarantee a fully validated Steam Deck gameplay experience and should be treated as an early compatibility distribution.

## Files installed and backed up

The package only backs up the files it is expected to replace, such as:

- `Retail/dinput8.dll`
- `Retail/ZHMModSDK.dll`
- `Retail/mods.ini`
- `Retail/mods/HitmanCoop.dll`

Backups are stored in a dedicated state directory outside the game install, not inside the `Retail` folder.

