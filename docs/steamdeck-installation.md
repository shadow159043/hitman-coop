# Artur Edition Steam Deck / Linux (Proton) installation

**Release download:** [R2.18.1 — Windows and Steam Deck/Linux packages](https://github.com/shadow159043/hitman-coop/releases/tag/artur-r2.18.1-npc-disguise-safety-20261031). Choose **`HitmanCoop-Artur-R2.18.1-SteamDeck-Linux-Proton.zip`** for Linux; Windows players choose **`HitmanCoop-Artur-R2.18.1-Windows-Setup.exe`**.

**Distribution:** Steam Deck / Proton experimental compatibility installer for Windows Artur Edition **R2.18.1 (v0.12.21)**. This package deliberately shares the Windows mod DLL and protocol 16; it is **not** a Linux-native rewrite.

## Verified compatibility (November 1, 2026)

On a physical PC booted directly into **Ubuntu 24.04.5 LTS** from an external Samsung T9 SSD, the AMD RADV Vulkan driver and Steam **Proton Experimental** ran HITMAN World of Assassination. The user tested Artur Edition **R2.18.1** installation and verification through Mission Control, confirmed ZHMModSDK and Co-op loaded, and successfully played **Windows ↔ Ubuntu multiplayer using Steam invitations**. This is a user-reported live test, **not** a measured performance benchmark or a physical Steam Deck test. Steam Deck controllers, UI and device-specific compatibility remain unverified.

## Installing

### Recommended: standalone installer (no extraction)

On a Steam Deck, switch to **Desktop Mode** and download `Artur-Edition-R2.18.1-SteamDeck-Linux-Installer-x86_64.AppImage` from the [R2.18.1 release](https://github.com/shadow159043/hitman-coop/releases/tag/artur-r2.18.1-npc-disguise-safety-20261031).

1. In **Dolphin**, right-click the AppImage → **Properties → Permissions**, and enable **Is executable** if needed. Downloaded programs require this trust step on Linux.
2. **Double-click the AppImage** to open **Mission Control** directly. The mod's original DLLs are already bundled inside; you do not extract a ZIP or run terminal commands.
3. Choose **Install**, confirm the detected HITMAN folder, then choose **Verify**.
4. Launch HITMAN normally through **Steam using Proton Experimental**. The AppImage is an installer, **not** the game executable.
5. Keep the AppImage if you want to return to Mission Control later for repair or uninstall.

**Compatibility note:** Some Linux systems require a compatible FUSE/AppImage runtime. The installer is tested in automated Ubuntu CI, but **has not yet been tested on physical Steam Deck hardware**. If double-clicking fails, use the ZIP alternative below.

### Alternative: extract the ZIP and launch from Dolphin

Install HITMAN World of Assassination through Steam, confirm it starts without mods, close the game, and switch to Steam Deck Desktop Mode. In Steam Properties > Compatibility select **Proton Experimental**.

Download **`HitmanCoop-Artur-R2.18.1-SteamDeck-Linux-Proton.zip`** from the [R2.18.1 release](https://github.com/shadow159043/hitman-coop/releases/tag/artur-r2.18.1-npc-disguise-safety-20261031). Extract it into a folder you intend to keep (such as `~/Downloads/ArturEdition`). In Steam Deck **Desktop Mode**, open that folder in **Dolphin** and double-click **`INSTALL-ARTUR-EDITION.desktop`**. If SteamOS asks whether to trust or execute the downloaded shortcut, choose **Launch/Execute**. The ZIP includes Linux executable permissions; if another archive tool strips them, use the launcher's **Properties → Permissions → Is executable** setting. This opens Mission Control with no Terminal commands.

If the desktop launcher cannot open, use this fallback in the extracted directory:

```bash
bash steamdeck/ui-install.sh --gui
```

Steam Deck Desktop Mode uses KDE's built-in `kdialog`. Ubuntu/GNOME users should install Zenity with `sudo apt install -y zenity` before launching the graphical interface. It provides a clickable menu for **Install, Verify, Launch, Repair, Restore, Uninstall, Status, Help** and requires confirmation for modifications. If no dialog provider is available, run `bash steamdeck/ui-install.sh --terminal`. To add a graphical app-menu shortcut after extracting the ZIP, run `bash steamdeck/install-shortcut.sh`; keep the extracted package in that location.

To launch the modded game on subsequent sessions, start **HITMAN from Steam normally using Proton Experimental**; the mod is installed inside the game's `Retail` folder. Mission Control is a separate installer/verification/repair tool, not an alternative game executable. For Steam Deck use **Desktop Mode** to run the installer. The clickable launcher and GUI open safely without modifying HITMAN. A Linux desktop may show a one-time trust/execute prompt for downloaded `.desktop` shortcuts. It will offer manual folder selection if Steam library discovery fails; selecting a folder alone does not install anything. The launch button requests the official Steam game and does not prove that Proton or multiplayer works.

Alternatively:

```bash
bash steamdeck/install.sh
bash steamdeck/verify.sh
bash steamdeck/launch.sh
```

If the package is labeled **installer-only**, download the exact matching Windows R2.18.1 ZIP and use `bash steamdeck/install.sh --package "/path/to/windows-release.zip"`.

The installer reads Steam's library manifests, handles Steam Deck microSD libraries listed there, and installs exact DLLs at `Retail/` and `Retail/mods/HitmanCoop.dll`. It creates/enables `[HitmanCoop]` in `Retail/mods.ini` without deleting unrelated sections, and refuses installation if `[AssassinRivals2]` is active.

If auto-discovery fails, pass `--game "/full/path/to/HITMAN game directory"`. You can pass `Retail` itself.

## Proton and Steam invitations

Keep the game launched through its **actual Steam game entry** (App ID **1659040**) so official Steam integration remains available. The launcher does not fake entitlement, change the App ID, or launch the Windows executable with an arbitrary Proton prefix.

According to [ZHMModSDK's official Steam Deck instructions](https://github.com/OrfeasZ/ZHMModSDK/blob/master/INSTALL-deck.md), Proton Experimental can work without overrides; older Proton configurations may require this **Steam game launch option**:

```bash
WINEDLLOVERRIDES="dinput8.dll=n,b;zhmmodsdk.dll=n,b" %command%
```

Save existing Steam launch options before adding this, and do not apply it globally to other games. The launcher does not automatically edit Steam user configuration.

On Deck, map the CO-OP menu's keyboard shortcut to a Steam Input rear button. Use trackpad/mouse emulation for the in-game UI if needed.

## Confirming functionality

The local `verify.sh` command confirms that the expected Artur DLL and SDK files remain present with their recorded checksums, **not that they load in a running game**.

Real-device testers should verify these steps in sequence:
1. HITMAN launches under Proton.
2. ZHMModSDK loads and the CO-OP tab appears without version warnings.
3. The Steam overlay opens and invitation reaches a Windows friend.
4. The Steam Deck successfully joins a Windows **R2.18.1** host using protocol 16.
5. Both players see movement, animations, NPC takedowns, shared items, and shared disguises.
6. Both players try invitation/host reversal and reconnect after a mission change.

Test using a Windows PC as the second peer. The existing Windows version is not modified by this package.

## Repair and rollback

```bash
bash steamdeck/repair.sh --package "/path/to/windows-release.zip"
bash steamdeck/uninstall.sh
```

The installer keeps a file-specific backup and manifest under `~/.local/state/hitman-coop-artur-deck/` (or `$XDG_STATE_HOME`). Uninstall restores originals and removes newly created files; it refuses to overwrite any file changed since installation. Keep that state directory for rollback.

If installation fails, preserve any error text. Report which installation step failed without sharing IP addresses, room passwords, Steam account IDs or private logs.

## Automated Linux checks on GitHub

The separate `Steam Deck Linux CI` workflow in `.github/workflows/steamdeck-linux-ci.yml` runs on **Ubuntu 24.04 and 26.04** for updates to the Steam Deck package and PRs into `main`. It also supports manual runs from GitHub Actions.

The checks include Bash syntax, ShellCheck errors, Python source compilation, desktop-entry validation, existing simulated installation/restore tests, and a Linux-only test of ZIP importing, checksum rejection, path traversal rejection, and malicious symlink rejection.

After checks pass, CI provides an **installer-only** test ZIP artifact for inspection. It does **not** include the Windows DLLs; use the standalone offline ZIP made on the development machine or import the matching Windows release ZIP. No Steam credentials or installed game are required by CI.

GitHub Actions is a Linux runner, not SteamOS or actual Steam Deck hardware; passing checks does not prove that the mod loads under Proton or that Steam invitations work.

## Status and limitations

Automated regression tests use simulated directories. In addition, live Ubuntu/Proton gameplay and Windows ↔ Ubuntu multiplayer were verified by the user on November 1, 2026 (see above). **Steam Deck hardware has not yet been tested**; Steam Deck support remains experimental and is not a guarantee of performance or controller compatibility. R2.18.1 body dragging can still be inconsistent; optional friendly fire and player fistfights remain **experimental**.

License and attribution: original HITMAN Co-op by Jordan Rodrigues, GPL-3.0-or-later; ZHMModSDK by OrfeasZ.
