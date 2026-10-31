# Package Artur's branded installer with the already two-PC-tested experimental R2 bits.
# Original HITMAN Co-op author: Jordan Rodrigues; GPL-3.0-or-later.
# No game files are modified by this packaging script.
param(
    [string]$OutDir = (Join-Path $PSScriptRoot "..\_dist")
)
$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$R2 = Join-Path $Root "_dist\HitmanCoop-0.12.1-3290-sdk420-EXPERIMENTAL-R2"
$NetTest = Join-Path $Root "_build-sdk420\core\RelWithDebInfo\HitmanCoop-NetTest.exe"
$Stage = Join-Path $OutDir "_artur-r2-stage"
$Payload = Join-Path $OutDir "_artur-r2-payload.zip"
$Setup = Join-Path $OutDir "HitmanCoop-Setup-by-Artur-EXPERIMENTAL-R2.exe"
$Csc = Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$Fx = Split-Path $Csc
foreach ($f in @((Join-Path $R2 "Retail\mods\HitmanCoop.dll"), (Join-Path $R2 "Retail\ZHMModSDK.dll"), $NetTest, $Csc)) {
    if (!(Test-Path $f)) { throw "Required R2 file missing: $f" }
}
New-Item -ItemType Directory -Force $OutDir | Out-Null
Remove-Item $Stage,$Payload -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force (Join-Path $Stage "files\mods") | Out-Null
Copy-Item (Join-Path $R2 "Retail\*") (Join-Path $Stage "files") -Recurse -Force
Copy-Item $NetTest (Join-Path $Stage "Test-Connection.exe")
Copy-Item (Join-Path $R2 "HITMAN-COOP-LICENSE.txt") (Join-Path $Stage "LICENSE.txt")
Copy-Item (Join-Path $R2 "SDK-LICENSE.txt") (Join-Path $Stage "SDK-LICENSE.txt")
Copy-Item (Join-Path $R2 "READ-ME-FIRST.txt") (Join-Path $Stage "READ-ME-FIRST.txt")
Copy-Item (Join-Path $R2 "NATIVE-AUDIT.md") (Join-Path $Stage "NATIVE-AUDIT.md")

# Installer from the original source, with version and mod-conflict guards for this fork only.
$Installer = Get-Content (Join-Path $Root "installer\installer.ps1") -Raw
$Installer = $Installer.Replace('$TestedGame = "3.280.0"', '$TestedGame = "3.290.1"')
$Installer = [regex]::Replace($Installer,
    '(?m)^\s*Say "Note: this build of HITMAN Co-op was tested on game version.*$',
    '        throw "This R2 edition requires HITMAN 3.290.1.x; detected $($Info.Version). No files were changed."')
$Guard = '    if (Test-Path (Join-Path $Retail "mods\AssassinRivals2.dll")) { throw "Disable Assassin Rivals 2 before installing this experimental Co-op build." }'
$Installer = $Installer.Replace('    $Stamp = Get-Date -Format "yyyyMMdd-HHmmss"', $Guard + "`r`n    " + '$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"')
if ($Installer -notmatch 'requires HITMAN 3.290.1' -or $Installer -notmatch 'Disable Assassin Rivals 2') {
    throw "Packaging safety modifications did not apply."
}
Set-Content -Path (Join-Path $Stage "installer.ps1") -Value $Installer -Encoding UTF8

Compress-Archive -Path (Join-Path $Stage "*") -DestinationPath $Payload -CompressionLevel Optimal -Force
$Icon = Join-Path $Root "installer\setup\setup.ico"
$Manifest = Join-Path $Root "installer\setup\setup.manifest"
$Source = Join-Path $Root "installer\setup\Setup.cs"
& $Csc /nologo /target:winexe /optimize+ "/out:$Setup" "/win32icon:$Icon" "/win32manifest:$Manifest" "/resource:$Payload,payload.zip" /r:System.Windows.Forms.dll /r:System.Drawing.dll "/r:$Fx\System.IO.Compression.dll" "/r:$Fx\System.IO.Compression.FileSystem.dll" $Source
if ($LASTEXITCODE -ne 0) { throw "C# setup compilation failed with exit code $LASTEXITCODE" }
$Hash = (Get-FileHash -Algorithm SHA256 $Setup).Hash.ToLowerInvariant()
Set-Content -Path "$Setup.sha256" -Value "$Hash  $(Split-Path $Setup -Leaf)"
Write-Host "OUTPUT: $Setup"
Write-Host "SHA256: $Hash"
Write-Host "NOTE: Package is experimental R2 for game 3.290.1.x only."
Remove-Item $Stage,$Payload -Recurse -Force
