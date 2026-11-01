# HITMAN Co-op — Artur Edition | Steam Deck / Proton (EXPERIMENTAL)

This is a **separate Steam Deck installer and launcher**, not a native Linux port. It installs the exact Windows **Artur Edition R2.18.1 / 0.12.21** runtime into the Steam version of HITMAN World of Assassination and launches the original game via Steam (App ID **1659040**) and Proton. Multiplayer protocol remains **16**, SDK version **4.2.1**. No Windows source code is changed.

**Unverified on physical Steam Deck hardware.** Installing files correctly does not establish that ZHMModSDK, Steam invitations or multiplayer work under Proton.

## Quick start (Steam Deck Desktop Mode)

1. Close HITMAN. Ensure HITMAN World of Assassination is installed through Steam and select **Proton Experimental** in its Steam Properties > Compatibility.
2. Extract this Steam Deck ZIP to a writable folder (for example Downloads).
3. Open a terminal in the extracted folder and run `bash steamdeck/ui-install.sh` for a menu, or run `bash steamdeck/install.sh` to install the included Windows mod payload.
4. If this is an **installer-only** package without the payload, supply the original Windows R2.18.1 ZIP: `bash steamdeck/install.sh --package "/path/to/HitmanCoop-0.12.21-....zip"`.
5. To confirm the file layout and checksums, run `bash steamdeck/verify.sh`.
6. Launch HITMAN **from the normal Steam game entry** (or run `bash steamdeck/launch.sh`). Open the CO-OP menu as usual.

The scripts detect Steam libraries through `libraryfolders.vdf` and `appmanifest_1659040.acf`. To choose the game manually, use `--game "/path/to/HITMAN World of Assassination"` (the `Retail` folder also works).

## Additional actions

- `bash steamdeck/repair.sh --package "/path/to/Windows-release.zip"` restores a missing installed mod file.
- `bash steamdeck/restore.sh` or `bash steamdeck/uninstall.sh` restores original mod files and removes Artur Edition-added files.
- `bash steamdeck/install-shortcut.sh` installs a Desktop Mode menu shortcut for the experimental Mission Control interface.
- `bash steamdeck/tests/run-tests.sh` runs simulated Linux-compatible installation tests.

A file-specific backup and manifest are stored outside the game under `$XDG_STATE_HOME/hitman-coop-artur-deck` or `~/.local/state/hitman-coop-artur-deck`. The installer refuses to overwrite modified files on repair/uninstall and preserves other mod configuration sections. Keep the backup directory until satisfied with restoration.

## Proton and controller notes

Prefer Proton Experimental, following the [official ZHMModSDK Steam Deck guide](https://github.com/OrfeasZ/ZHMModSDK/blob/master/INSTALL-deck.md). Older Proton versions may require `WINEDLLOVERRIDES="dinput8.dll=n,b;zhmmodsdk.dll=n,b" %command%` in HITMAN's Steam launch options; do not replace any existing launch options without preserving them.

The game uses an in-game CO-OP menu activated by a keyboard hotkey. Steam Input can map a rear button to the `~` key and use the trackpad as a mouse; this has not been tested on a Deck.

**Known limitations:** Steam Deck P2P and invitation behavior unverified; body dragging remains imperfect on Windows as well; occasional item visibility issues may occur. Fistfights and friendly fire are experimental. Never reuse account passwords as co-op room passwords because room password transport is unencrypted.

Original HITMAN Co-op by Jordan Rodrigues (GPL-3.0-or-later), ZHMModSDK by OrfeasZ; Artur Edition is an independent compatibility fork. Retain all bundled license notices. Unofficial project, not endorsed by IO Interactive.
