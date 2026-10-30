# Stage only; intentionally does not touch installed HITMAN files.
$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Output = Join-Path $Root '_dist\HitmanCoop-0.12.1-3290-sdk420-EXPERIMENTAL-R2'
$Retail = Join-Path $Output 'Retail'
$SDK = Join-Path $Root '_deps-sdk420\sdk-release'
$Built = Join-Path $Root '_build-sdk420\plugin\RelWithDebInfo\HitmanCoop.dll'
if (-not (Test-Path $Built)) { throw "Build the SDK 4.2.0 DLL first, using tools/build-sdk420.ps1" }
if (Test-Path $Output) { throw "Staging already exists: $Output. Move/rename it before running again." }
New-Item -ItemType Directory -Force (Join-Path $Retail 'mods') | Out-Null
foreach ($File in @('dinput8.dll','ZHMModSDK.dll','ResourceLib_HM3.dll','discord_game_sdk.dll','crashpad_handler.exe')) {
    $Src = Join-Path $SDK $File
    if (-not (Test-Path $Src)) { throw "Missing SDK v4.2.0 runtime: $File" }
    Copy-Item -LiteralPath $Src -Destination (Join-Path $Retail $File)
}
Copy-Item -LiteralPath $Built -Destination (Join-Path $Retail 'mods\HitmanCoop.dll')
Copy-Item -LiteralPath (Join-Path $Root 'LICENSE') -Destination (Join-Path $Output 'HITMAN-COOP-LICENSE.txt')
Copy-Item -LiteralPath (Join-Path $SDK 'LICENSE') -Destination (Join-Path $Output 'SDK-LICENSE.txt')
Copy-Item -LiteralPath (Join-Path $Root 'docs\native-audit-3290.md') -Destination (Join-Path $Output 'NATIVE-AUDIT.md')
@'
EXPERIMENTAL / NOT GAMEPLAY-VERIFIED / DO NOT HOT-SWAP DLLS

HITMAN Co-op v0.12.1 fork for HITMAN3.exe 3.290.1.0 + official ZHMModSDK 4.2.0.
Uses current SDK actor/outfit memory offsets, revised marker fallback and
outfit-kit early-return safety, plus 83 automated tests and avatar diagnostics.
R2 also prevents stand-in spawning with unresolvable outfit kits, validates
pose-buffer/vtable memory before hooking, and audits 10 game-code signatures.
Contains native PoseHook/RigScan/CrashGuards private assumptions not yet
validated in the October game. No guarantees against crashes or save issues.

THIS IS NOT AN INSTALLER. Nothing in this folder changes your game automatically.
Do not overwrite the existing Steam/HITMAN installation without a complete,
verified rollback backup and a separate native-hook review. Do not have
AssassinRivals2.dll and this Co-op DLL active at the same time for the first test.

Suggested controlled test (after a native-hook review):
- Quit HITMAN fully and back up all existing Retail/mods and SDK runtime files.
- Use only matching versions on BOTH PCs.
- Verify the game executable is 3.290.1.0 on both PCs.
- Once tested, in-game ~ > CO-OP > About > Copy diagnostics on both PCs.
- New "Avatar transforms" queued/received/read failures isolate the invisible-player cause.
- Restore old runtime and mod DLLs while game is closed if any instability appears.

Local git branch: fix/3290-remote-player
Sources and build procedure in the separate HitmanCoop-Bugfix-20261030 workspace.
Official upstream: https://github.com/JordanRodrigues021/hitman-coop
'@ | Set-Content -LiteralPath (Join-Path $Output 'READ-ME-FIRST.txt') -Encoding UTF8
$Lines = @()
Get-ChildItem -File -Recurse $Retail | ForEach-Object {
  $Rel = $_.FullName.Substring($Output.Length + 1)
  $Hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
  $Lines += "$Hash  $Rel"
}
$Lines | Set-Content -LiteralPath (Join-Path $Output 'SHA256SUMS.txt') -Encoding UTF8
Write-Host "Experimental test payload staged (not installed) at $Output"
$Zip = "$Output.zip"
Compress-Archive -Path (Join-Path $Output '*') -DestinationPath $Zip -CompressionLevel Optimal
Write-Host "Experimental archive: $Zip"
