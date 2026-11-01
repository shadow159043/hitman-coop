# Artur Edition Steam Deck installer and testing

**Distribution:** Steam Deck / Proton experimental compatibility installer for Windows Artur Edition **R2.18.1 (v0.12.21)**. This package deliberately shares the Windows mod DLL and protocol 16; it is **not** a Linux-native rewrite.

## Installing

Install HITMAN World of Assassination through Steam, confirm it starts without mods, close the game, and switch to Steam Deck Desktop Mode. In Steam Properties > Compatibility select **Proton Experimental**.

Extract the experimental Steam Deck ZIP into Downloads. Open the extracted folder in a terminal and run:

```bash
bash steamdeck/ui-install.sh
```

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

## Status and limitations

Automated tests use simulated directories, not a real Linux Steam game. The project does not assert actual Steam Deck compatibility or performance until real hardware testing. R2.18.1 body dragging can still be inconsistent; optional friendly fire and player fistfights remain **experimental**.

License and attribution: original HITMAN Co-op by Jordan Rodrigues, GPL-3.0-or-later; ZHMModSDK by OrfeasZ.
