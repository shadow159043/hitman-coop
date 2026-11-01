# HITMAN Co-op — Artur Edition | Steam Deck / Proton (EXPERIMENTAL)

This is a **separate Steam Deck installer and launcher**, not a native Linux port. It installs the exact Windows **Artur Edition R2.18.1 / 0.12.21** runtime into the Steam version of HITMAN World of Assassination and launches the original game via Steam (App ID **1659040**) and Proton. Multiplayer protocol remains **16**, SDK version **4.2.1**. No Windows source code is changed.

**Verified on physical Ubuntu 24.04.5 + AMD Vulkan hardware, November 1, 2026:** Proton Experimental loaded HITMAN, ZHMModSDK, and Artur Edition; a Windows player successfully connected to the Ubuntu player using Steam invitations. **Physical Steam Deck hardware and its controls remain untested.**

## Quick start (Steam Deck Desktop Mode)

1. Download **`HitmanCoop-Artur-R2.18.1-SteamDeck-Linux-Proton.zip`** from the [R2.18.1 release](https://github.com/shadow159043/hitman-coop/releases/tag/artur-r2.18.1-npc-disguise-safety-20261031). Windows users should use **`HitmanCoop-Artur-R2.18.1-Windows-Setup.exe`** instead. Close HITMAN. Ensure HITMAN World of Assassination is installed through Steam and select **Proton Experimental** in its Steam Properties > Compatibility.
2. Extract this Steam Deck ZIP to a writable folder (for example Downloads).
3. For a clickable **graphical Mission Control**, run `bash steamdeck/ui-install.sh --gui`. Steam Deck's KDE uses `kdialog`; on Ubuntu GNOME, install Zenity first with `sudo apt install -y zenity`. The interface automatically chooses a supported dialog toolkit. Use `bash steamdeck/ui-install.sh --terminal` if you prefer the text menu.
4. The graphical menu provides **Install, Verify, Launch, Repair, Restore, Uninstall, Status, and Help**. It displays the detected game folder and whether the mod is installed. Nothing is installed merely by opening the menu.
5. Optionally run `bash steamdeck/install-shortcut.sh` to add a **Mission Control launcher** to the Linux application menu. Keep the extracted package in its original location afterward.
6. To install directly without the GUI, run `bash steamdeck/install.sh` with the bundled Windows runtime.
7. If this is an **installer-only** package without the payload, supply the original Windows R2.18.1 ZIP: `bash steamdeck/install.sh --package "/path/to/HitmanCoop-0.12.21-....zip"`.
8. Confirm the installed files and checksums with `bash steamdeck/verify.sh`.
9. **Launch HITMAN normally from your Steam Library** with Proton Experimental (or use Mission Control **Launch** / `bash steamdeck/launch.sh`). The installed mod loads within the Steam game; open the ZHMModSDK **CO-OP** menu using `~`.

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

**Known limitations:** Windows ↔ Ubuntu Steam invitations and multiplayer were user-tested successfully; physical Steam Deck P2P, controls, and performance remain unverified; body dragging remains imperfect on Windows as well; occasional item visibility issues may occur. Fistfights and friendly fire are experimental. Never reuse account passwords as co-op room passwords because room password transport is unencrypted.

Original HITMAN Co-op by Jordan Rodrigues (GPL-3.0-or-later), ZHMModSDK by OrfeasZ; Artur Edition is an independent compatibility fork. Retain all bundled license notices. Unofficial project, not endorsed by IO Interactive.
