# Inspect a built setup without running INSTALL or modifying the game.
param([string]$SetupPath = (Join-Path $PSScriptRoot "..\_dist\HitmanCoop-Setup-by-Artur-EXPERIMENTAL-R2.12-FIST-DUEL-TEST.exe"))
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$FullSetup = (Resolve-Path $SetupPath).Path
$Temp = Join-Path ([IO.Path]::GetTempPath()) ("HitmanCoop-Payload-Test-" + [guid]::NewGuid().ToString("N"))
New-Item $Temp -ItemType Directory -Force | Out-Null
try {
    $Assembly = [Reflection.Assembly]::LoadFile($FullSetup)
    $Resource = $Assembly.GetManifestResourceStream("payload.zip")
    if (-not $Resource) { throw "Installer does not embed payload.zip" }
    $EmbeddedZip = Join-Path $Temp "payload.zip"
    $DestStream = [IO.File]::Create($EmbeddedZip)
    try { $Resource.CopyTo($DestStream) } finally { $DestStream.Dispose(); $Resource.Dispose() }
    $Extracted = Join-Path $Temp "extracted"
    [IO.Compression.ZipFile]::ExtractToDirectory($EmbeddedZip, $Extracted)

    $InstallScript = Join-Path $Extracted "installer.ps1"
    $Dll = Join-Path $Extracted "files\mods\HitmanCoop.dll"
    if (-not (Test-Path $InstallScript) -or -not (Test-Path $Dll)) { throw "Embedded installer or co-op DLL missing" }
    $ScriptText = Get-Content $InstallScript -Raw
    foreach ($Marker in @("appmanifest_1659040.acf", "LauncherInstalled.dat", "Find-LegendaryGames", "Assassin Rivals 2 is enabled in Retail/mods.ini")) {
        if (-not $ScriptText.Contains($Marker)) { throw "Embedded installer lacks required feature: $Marker" }
    }
    Write-Output "PASS: Auto-discovery and disabled-mod guard embedded in installer"
    $OriginalDll = Join-Path $Root "_build-sdk420\plugin\RelWithDebInfo\HitmanCoop.dll"
    if ((Get-FileHash $Dll).Hash -ne (Get-FileHash $OriginalDll).Hash) { throw "Installer contains stale plugin" }
    Write-Output "PASS: Embedded plugin matches latest compiled in-game Artur UI"
    $Actual = @( & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $InstallScript -ListGames )
    if ($LASTEXITCODE -ne 0) { throw "Embedded installer game detection returned an error" }
    if (-not @($Actual | Where-Object { Test-Path (Join-Path $_ "Retail\HITMAN3.exe") }).Count) {
        throw "Embedded installer did not detect a valid HITMAN installation on this PC"
    }
    Write-Output ("PASS: Embedded installer detected HITMAN: " + ($Actual -join "; "))

    $Zip = Join-Path $Root "_dist\HitmanCoop-0.12.11-3290-sdk420-EXPERIMENTAL-R2.12-FIST-DUEL-TEST.zip"
    $Archive = [IO.Compression.ZipFile]::OpenRead($Zip)
    try {
        $Plugin = @($Archive.Entries | Where-Object { $_.FullName -match '(?i)[\\/]Retail[\\/]mods[\\/]HitmanCoop.dll$' }) | Select-Object -First 1
        if (-not $Plugin) {throw "R2.2 ZIP lacks the Co-op DLL"}
        $Hash = [Security.Cryptography.SHA256]::Create()
        $Stream = $Plugin.Open()
        try { $ActualHash = [BitConverter]::ToString($Hash.ComputeHash($Stream)).Replace("-", "") }
        finally { $Stream.Dispose(); $Hash.Dispose() }
        if ($ActualHash -ne (Get-FileHash $OriginalDll).Hash) {throw "R2.2 ZIP does not match compiled plugin"}
    }
    finally { $Archive.Dispose() }
    Write-Output "PASS: R2.12 fist-duel ZIP has the identical branded plugin"
    Write-Output "PASS: All package checks completed; no game files changed"
}
finally {
    Remove-Item $Temp -Recurse -Force -ErrorAction SilentlyContinue
}
