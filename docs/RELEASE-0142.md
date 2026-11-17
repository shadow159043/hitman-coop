# HITMAN Co-op — Artur Edition 0.14.2 (Experimental)

**Compatibility hotfix:** Addresses the "game 3.290.1.0 with ZHMModSDK runtime 4.2.0.0 required" warning reported in Artur Edition 0.14.0 and 0.14.1.

## Which file should I download?

| Device | Download |
| --- | --- |
| **Windows PC (recommended)** | `Windows-PC-Artur-Edition-0.14.2-Setup.exe` |
| **Steam Deck (Desktop Mode)** | `Steam-Deck-Artur-Edition-0.14.2-Installer.AppImage` |
| **Linux PC / Proton** | `Linux-PC-Artur-Edition-0.14.2-Installer.tar.gz` |
| **Windows ZIP alternative** | `Windows-PC-Artur-Edition-0.14.2-ZIP-Installer.zip` |

Files ending in `.sha256` are checksums, not installers. The source code archives are not required for installation.

## Fixed in 0.14.2

- The 3.290 build now recognizes HITMAN **3.290.1.0** together with **ZHMModSDK 4.2.1.0**, the actual SDK version bundled and built in 0.14.1. The previous safety check erroneously required SDK 4.2.0.0, disabling co-op on a correctly installed game.
- The 3.280 build uses its own game **3.280.x** / **ZHMModSDK 4.1.1.0** pairing, instead of incorrectly enforcing the 3.290 requirement.
- Unknown versions and mismatched SDKs continue to be rejected *before* any native hooks are installed.
- Regression tests exercise supported combinations and the mismatches that must remain blocked.
- Retains the previously shipped mission restart guards and separate Artur Edition signed update checker.

## Important installation and updater note

**You must manually install this 0.14.2 hotfix once**, even if you've installed 0.14.1: the compatibility guard in 0.14.1 prevents the updater thread from starting.

The independent signed Artur Edition update channel currently remains at **0.14.1**. This release includes the in-game update checker but is not yet available from that signed feed; future unattended updates require publishing a fresh signed manifest from the offline private key. The old 0.14.1 installer also cannot update itself.

Close HITMAN before installing. After using the matching installer, reopen HITMAN and confirm that the overlay says **v0.14.2** and the incorrect 4.2.0.0 warning is gone.

**Experimental:** Automated build and regression tests cannot prove real-world two-player stability or physical Steam Deck compatibility. Try restarting a mission together; collect bug reports if a crash occurs.

Network protocol **21**: both players should install the same Artur Edition release. Incompatible with official Jordan v0.14.0 (protocol 18) and older Artur R2.18.1 (protocol 16).

Original HITMAN Co-op created by **Jordan Rodrigues**, with contributions credited in [CREDITS.md](https://github.com/shadow159043/hitman-coop/blob/feature/artur-upstream-014-integration/CREDITS.md). Independent GPL-3.0-or-later fan-made fork, not affiliated with IO Interactive.
