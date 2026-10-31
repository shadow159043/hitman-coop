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
$NewDll = Join-Path $Root "_build-sdk420\plugin\RelWithDebInfo\HitmanCoop.dll"
$Stage = Join-Path $OutDir "_artur-r2-stage"
$Payload = Join-Path $OutDir "_artur-r2-payload.zip"
$Setup = Join-Path $OutDir "HitmanCoop-Setup-by-Artur-EXPERIMENTAL-R2.6-TEST.exe"
$Csc = Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$Fx = Split-Path $Csc
foreach ($f in @((Join-Path $R2 "Retail\mods\HitmanCoop.dll"), (Join-Path $R2 "Retail\ZHMModSDK.dll"), $NetTest, $NewDll, $Csc)) {
    if (!(Test-Path $f)) { throw "Required R2 file missing: $f" }
}
New-Item -ItemType Directory -Force $OutDir | Out-Null
Remove-Item $Stage,$Payload -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force (Join-Path $Stage "files\mods") | Out-Null
Copy-Item (Join-Path $R2 "Retail\*") (Join-Path $Stage "files") -Recurse -Force
# Use the freshly built in-game UI DLL; do not accidentally repackage the old R2 UI.
Copy-Item $NewDll (Join-Path $Stage "files\mods\HitmanCoop.dll") -Force
Copy-Item $NetTest (Join-Path $Stage "Test-Connection.exe")
Copy-Item (Join-Path $R2 "HITMAN-COOP-LICENSE.txt") (Join-Path $Stage "LICENSE.txt")
Copy-Item (Join-Path $R2 "SDK-LICENSE.txt") (Join-Path $Stage "SDK-LICENSE.txt")
Copy-Item (Join-Path $R2 "READ-ME-FIRST.txt") (Join-Path $Stage "READ-ME-FIRST.txt")
$ReadmeIntro = "R2.6 TEST / v0.12.5 (protocol 16): clearer room-code/IP/password fields and full-invite paste; experimental held weapon visuals, big weapon back attachments, cosmetic dropped-item replicas when scene IDs differ. Keeps R2.5 item/disguise/drag candidates and R2.4 movement/combat fixes. New visual features are NOT VERIFIED in live two-PC gameplay. Cosmetic dropped-item copies cannot be picked up. Both players need v0.12.5, HITMAN 3.290.1.x and ZHMModSDK 4.2.0. Room passwords are NOT encrypted. Original mod by Jordan Rodrigues, GPL-3.0-or-later."
$ReadmeOriginal = Get-Content (Join-Path $Stage "READ-ME-FIRST.txt") -Raw
Set-Content (Join-Path $Stage "READ-ME-FIRST.txt") -Value ($ReadmeIntro + [Environment]::NewLine + $ReadmeOriginal) -Encoding UTF8
Copy-Item (Join-Path $R2 "NATIVE-AUDIT.md") (Join-Path $Stage "NATIVE-AUDIT.md")

# Installer from the original source, with version and mod-conflict guards for this fork only.
$Installer = Get-Content (Join-Path $Root "installer\installer.ps1") -Raw
$Installer = $Installer.Replace('$TestedGame = "3.280.0"', '$TestedGame = "3.290.1"')
$Installer = [regex]::Replace($Installer,
    '(?m)^\s*Say "Note: this build of HITMAN Co-op was tested on game version.*$',
    '        throw "This R2 edition requires HITMAN 3.290.1.x; detected $($Info.Version). No files were changed."')
$Guard = @'
    # SDK only loads enabled mod sections from Retail/mods.ini. A disabled mod can keep its DLL.
    $ModsIni = Join-Path $Retail "mods.ini"
    if (Test-Path -LiteralPath $ModsIni) {
        $RivalsEnabled = @(Get-Content -LiteralPath $ModsIni | Where-Object {
            $_ -match '^\s*\[AssassinRivals2\]\s*(?:[;#].*)?$'
        }).Count -gt 0
        if ($RivalsEnabled) {
            throw "Assassin Rivals 2 is enabled in Retail/mods.ini. Disable it in the SDK Mods menu, save, and close HITMAN before installing Co-op."
        }
    }
'@
$Installer = $Installer.Replace('    $Stamp = Get-Date -Format "yyyyMMdd-HHmmss"', $Guard + "`r`n    " + '$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"')
if ($Installer -notmatch 'requires HITMAN 3.290.1' -or $Installer -notmatch 'Assassin Rivals 2 is enabled in Retail/mods.ini') {
    throw "Packaging safety modifications did not apply."
}
Set-Content -Path (Join-Path $Stage "installer.ps1") -Value $Installer -Encoding UTF8

$R21 = Join-Path $OutDir "HitmanCoop-0.12.5-3290-sdk420-EXPERIMENTAL-R2.6-TEST"
$Zip21 = "$R21.zip"
Remove-Item $R21,$Zip21 -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item -Path $R2 -Destination $R21 -Recurse
Copy-Item $NewDll (Join-Path $R21 "Retail\mods\HitmanCoop.dll") -Force
Set-Content (Join-Path $R21 "READ-ME-FIRST.txt") -Value ($ReadmeIntro + [Environment]::NewLine + (Get-Content (Join-Path $R2 "READ-ME-FIRST.txt") -Raw)) -Encoding UTF8
$checks = @(Get-ChildItem $R21 -Recurse -File | Where-Object { $_.Name -ne "SHA256SUMS.txt" } | ForEach-Object { "{0}  {1}" -f (Get-FileHash -Algorithm SHA256 $_.FullName).Hash.ToLowerInvariant(), $_.FullName.Substring($R21.Length+1).Replace('\','/') })
Set-Content (Join-Path $R21 "SHA256SUMS.txt") -Value $checks -Encoding ascii
Compress-Archive -Path $R21 -DestinationPath $Zip21 -CompressionLevel Optimal -Force
$ZipHash = (Get-FileHash -Algorithm SHA256 $Zip21).Hash.ToLowerInvariant()
Set-Content "$Zip21.sha256" "$ZipHash  $(Split-Path -Leaf $Zip21)"
Write-Host "R2.6 TEST ZIP: $Zip21"
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
Write-Host "NOTE: R2.6 TEST requires both players on v0.12.5/protocol 16 and game 3.290.1.x; visual features unverified."
Remove-Item $Stage,$Payload -Recurse -Force
