# Publishing Windows + Steam Deck / Linux releases

Every new **Artur Edition** GitHub release should contain separate, unmistakably named **Windows** and **Steam Deck/Linux (Proton)** downloads. Do **not** replace Windows binaries with Linux installers: the Linux package reuses the **same exact Windows mod DLLs** through Proton.

## Release checklist

1. Build/test the Windows version and produce the matching Windows setup EXE and runtime ZIP. Name the assets `HitmanCoop-Artur-RX.Y-Windows-Setup.exe` and `HitmanCoop-Artur-RX.Y-Windows-Mod.zip` (use your actual release version).
2. Confirm both Windows assets are uploaded to the **same GitHub release** before publishing it. Never include unrelated backup archives as a normal download recommendation.
3. Update `steamdeck/release-versions.json` with the new release tag, exact Windows asset filenames, actual Co-op mod version, SDK version and protocol. Update `steamdeck/package-deck.ps1` if packaging requirements or payload contents change. Merge these changes to `main` **before** publishing the release.
4. Publish the GitHub release. The workflow [Attach Linux Proton package to Windows release](../.github/workflows/steamdeck-release-assets.yml) will download the matching Windows ZIP, package the offline Linux launcher/runtime and attach:
   - `HitmanCoop-Artur-RX.Y-SteamDeck-Linux-Proton.zip`
   - `HitmanCoop-Artur-RX.Y-SteamDeck-Linux-Proton.zip.sha256`
5. Check the workflow and GitHub release assets. If the event was missed, use Actions → **Attach Linux Proton package to Windows release** → Run workflow and supply the exact existing release tag. Never publish a mismatched Linux payload.
6. Update top-level README and the release notes with instructions for **both platforms**, version/protocol compatibility, and the difference between verified Ubuntu and untested physical Steam Deck hardware.

## Required Linux launch instructions in each release description

**Steam Deck / Linux (Proton):** Install HITMAN on Steam, select **Proton Experimental** in game Compatibility, launch unmodded HITMAN once, then close it. Download the **SteamDeck-Linux-Proton.zip** from this same release and extract to a permanent folder. In Steam Deck Desktop Mode or a Linux terminal, run `bash steamdeck/ui-install.sh --gui`. In the graphical Mission Control choose **Install → Verify**. Then launch **HITMAN normally from Steam**; the mod loads through Proton. Ubuntu GNOME may require `sudo apt install -y zenity unzip`. If the SDK fails to load, try `WINEDLLOVERRIDES="dinput8.dll=n,b;zhmmodsdk.dll=n,b" %command%` under HITMAN's Steam Launch Options. The Linux ZIP is **not** a native Linux build.

**Windows:** Download **Windows-Setup.exe**, close HITMAN, run the setup, click **Install**, then start HITMAN normally from Steam. Both players must use a matching version/protocol.

**Test status:** Windows ↔ Ubuntu 24.04.5 using Proton Experimental and AMD graphics passed the user's Steam-invite multiplayer test on November 1, 2026. Physical Steam Deck hardware has **not** been tested. Preserve caveats for subsequent releases until verified.

This automation intentionally **fails instead of bundling mismatched binaries** if the exact release tag or Windows ZIP/setup is absent from the manifest. Updating the manifest for each new version is mandatory.
