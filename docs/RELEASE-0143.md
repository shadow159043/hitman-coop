# HITMAN Co-op — Artur Edition 0.14.3 (Experimental)

**Windows launcher update checking is here.** When you open the **0.14.3 Windows setup**, it checks your fork's newest GitHub release, shows the newer version if one exists, and offers **Update now**.

## Which file should I download?

| Device | File |
|---|---|
| **Windows PC (recommended)** | `Windows-PC-Artur-Edition-0.14.3-Setup.exe` |
| **Steam Deck (Desktop Mode)** | `Steam-Deck-Artur-Edition-0.14.3-Installer.AppImage` |
| **Linux PC / Proton** | `Linux-PC-Artur-Edition-0.14.3-Installer.tar.gz` |
| **Windows ZIP alternative** | `Windows-PC-Artur-Edition-0.14.3-ZIP-Installer.zip` |

Files ending in `.sha256` are optional checksums; GitHub's source archives are not needed for installation.

## New: Check for updates from the Windows setup

- Automatically checks [your GitHub Releases page](https://github.com/shadow159043/hitman-coop/releases/latest) **when the 0.14.3 Windows installer is opened**, without blocking the interface.
- Displays **Update now** when a newer stable-tagged Artur Edition release has the expected Windows installer and matching checksum.
- Only accepts the installer belonging to this exact GitHub repository. Downloads that installer, verifies SHA-256 against its release checksum, then launches the new setup after you confirm.
- Carries forward your selected HITMAN folder. HITMAN should be closed before applying the update. The new setup handles the actual installation or repair.
- Offers **Check again** and graceful error handling if the internet is unavailable.
- **Important:** Old installers (0.14.2 and earlier) **cannot update themselves retroactively**. Download 0.14.3 manually once; later versions of the setup can be obtained through this new button.
- Only the **Windows installer** gains this launcher update action in 0.14.3. Steam Deck/Linux installation packages were rebuilt with the same version, but their launcher UI does not yet have this feature.
- This is separate from the in-game signed updater. The signed in-game update feed currently remains at 0.14.1; future signed in-game releases must be published from the private signing key.

## Existing compatibility fix

- Carries forward the 0.14.2 fix for HITMAN **3.290.1.0 + ZHMModSDK 4.2.1.0**, and for the separate 3.280.x + SDK 4.1.1.0 build.
- Unknown SDK/game combinations remain blocked before native hooks to prevent unintended crashes.
- Multiplayer mission restart safeguards, protocol 21, and diagnostics retained.

**Experimental:** Automated Windows builds, update-parser regressions, and Linux/AppImage smoke tests don't prove live gameplay, download/launch UI interaction, or physical Steam Deck behavior.

Both players should use **Artur Edition 0.14.3 / protocol 21**. It will not connect to Jordan's official protocol 18 or earlier Artur protocol 16. The older releases remain available for rollback.

Original HITMAN Co-op by **Jordan Rodrigues** and contributors, independent Artur Edition fork, GPL-3.0-or-later. Not affiliated with IO Interactive.
