# HITMAN Co-op — Artur Edition 0.14.1 (Experimental)

**Latest Artur Edition version, now with a fork-owned signed automatic updater.** Based on Jordan Rodrigues’s HITMAN Co-op v0.14.0, preserving Artur Edition’s multiplayer restart safeguards, diagnostics, installer, and Steam Deck/Proton support.

## Which file should I download?

| Device | File |
|---|---|
| **Windows PC (recommended)** | `Windows-PC-Artur-Edition-0.14.1-Setup.exe` |
| **Steam Deck** | `Steam-Deck-Artur-Edition-0.14.1-Installer.AppImage` (open in Desktop Mode) |
| **Linux PC with Proton** | `Linux-PC-Artur-Edition-0.14.1-Installer.tar.gz` |
| **Windows ZIP alternative** | `Windows-PC-Artur-Edition-0.14.1-ZIP-Installer.zip` |

Files ending with `.sha256` are optional download-integrity checks, not the installers. GitHub’s auto-generated “Source code” archives are not required.

## New: Artur Edition automatic updates

- **Enabled by default** for new Artur Edition 0.14.1 installations. Opt out at **CO-OP → About → Automatically download signed Artur Edition updates**.
- On launch, the mod checks `shadow159043/hitman-coop`’s separate **Artur Edition signed update channel**, not the original HITMAN Co-op updater.
- Update manifests are signed with a new fork-owned ECDSA P-256 key; downloaded files have verified SHA-256 hashes before replacement.
- Updates are staged while the game is running, then take effect **on the next game launch**. Mod version and matching HITMAN game build are checked.
- An installed 0.14.0 or R2.18.1 copy **does not contain the new updater**: install 0.14.1 manually once before future Artur Edition releases can update automatically.
- On Linux/Steam Deck, the game uses the same Windows plugin under Proton; compatibility of in-game background updating under Proton **has not yet been validated on physical Steam Deck hardware**. Manual installer updates remain available.
- Your downloaded AppImage is an **installer**; the in-game updater changes installed mod files, not the AppImage file itself.

## Existing fixes and features

- Protects mission restart packets against late delivery from previous scene runs, and blocks stale world events or skeleton resets during mission reloads.
- Includes upstream v0.14.0 improvements for NPCs, animations, dropped items, bodies, scripted actions, and multiplayer diagnostics.
- Includes HITMAN 3.290.x and 3.280.x DLLs with matching ZHMModSDK dependencies.
- Preserves Artur Edition’s identity and Steam Deck graphical installer.

## Important

- **Experimental release:** Windows and Linux CI/tests may pass without proving crash-free two-player gameplay, reliable restarting, or physical Steam Deck compatibility.
- Both players should update to 0.14.1; network **protocol 21** is incompatible with official Jordan v0.14.0 (protocol 18) and old Artur R2.18.1 (protocol 16).
- Back up your existing installed mod before upgrading. Older Artur releases remain on the [Releases page](https://github.com/shadow159043/hitman-coop/releases) for manual rollback.
- For a crash, use **CO-OP → About → Save bug report** on both computers. Do not post memory dumps publicly.
- Fan-made mod not affiliated with IO Interactive. Original HITMAN Co-op by **Jordan Rodrigues** and upstream contributors; this is an independent Artur Edition fork. GPL-3.0-or-later.

**Release source**: feature/artur-upstream-014-integration; signed update channel: `updates` branch.
