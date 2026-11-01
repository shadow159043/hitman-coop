# Produce an offline Steam Deck / Proton experiment using the existing Windows R2.18.1 ZIP.
# Packaging does not change the game or the Windows installer.
param(
  [string]$WindowsZip = (Join-Path (Join-Path $PSScriptRoot '..\_dist') 'HitmanCoop-0.12.21-3290-sdk421-EXPERIMENTAL-R2.18.1-NPC-DISGUISE-SAFETY.zip'),
  [string]$OutputDirectory = "$HOME\Downloads",
  [string]$ReleaseVersion = 'R2.18.1',
  [string]$ModVersion = '0.12.21',
  [string]$SDKVersion = '4.2.1',
  [int]$Protocol = 16
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (!(Test-Path -LiteralPath $WindowsZip)) { throw "Missing R2.18.1 source ZIP: $WindowsZip" }
$Stage = Join-Path ([IO.Path]::GetTempPath()) ('ArturDeck-' + [guid]::NewGuid().ToString('N'))
$Extract = Join-Path $Stage 'extracted'
$Bundle = Join-Path $Stage 'bundle'
$DeckOut = Join-Path $Bundle 'steamdeck'
$ZipName = "HitmanCoop-Artur-$ReleaseVersion-SteamDeck-Linux-Proton.zip"
New-Item -ItemType Directory -Force $Extract,$Bundle,$DeckOut | Out-Null
try {
    [IO.Compression.ZipFile]::ExtractToDirectory((Resolve-Path $WindowsZip).Path, $Extract)
    if ([IO.Path]::GetFileName($WindowsZip) -notmatch [regex]::Escape($ModVersion)) {
        throw "Windows ZIP name must include matching mod version $ModVersion to prevent mixed-release packaging: $WindowsZip"
    }
    $Plugin = @(Get-ChildItem -LiteralPath $Extract -Recurse -File -Filter 'HitmanCoop.dll' | Where-Object { $_.FullName -match '[\\/]Retail[\\/]mods[\\/]HitmanCoop.dll$' })
    if ($Plugin.Count -ne 1) { throw "Expected exactly one Retail/mods/HitmanCoop.dll inside Windows package" }
    $SourceRetail = Split-Path -Parent (Split-Path -Parent $Plugin[0].FullName)
    $Needed = @('dinput8.dll','ZHMModSDK.dll','crashpad_handler.exe','discord_game_sdk.dll','ResourceLib_HM3.dll','mods\HitmanCoop.dll')
    foreach ($File in $Needed) { if (!(Test-Path (Join-Path $SourceRetail $File))) { throw "Missing $File in Windows release" } }
    Copy-Item -LiteralPath (Join-Path $Repo 'steamdeck') -Destination $Bundle -Recurse -Force
    New-Item -ItemType Directory -Force (Join-Path $DeckOut 'payload\Retail'),(Join-Path $Bundle 'docs') | Out-Null
    Copy-Item -LiteralPath (Join-Path $Repo 'docs\steamdeck-installation.md') -Destination (Join-Path $Bundle 'docs')
    foreach ($File in $Needed) {
      $Target = Join-Path (Join-Path $DeckOut 'payload\Retail') $File
      New-Item -ItemType Directory -Force (Split-Path $Target -Parent) | Out-Null
      Copy-Item -LiteralPath (Join-Path $SourceRetail $File) -Destination $Target -Force
    }
    $ReleaseDir = Split-Path -Parent $SourceRetail
    foreach ($License in @('HITMAN-COOP-LICENSE.txt','SDK-LICENSE.txt','READ-ME-FIRST.txt')) {
      $Source = Join-Path $ReleaseDir $License
      if (Test-Path $Source) {Copy-Item -LiteralPath $Source -Destination $DeckOut -Force}
    }
    $Hashes = foreach ($File in $Needed) {
      $Relative = $File.Replace('\','/')
      $FileHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $SourceRetail $File)).Hash.ToLowerInvariant()
      "$FileHash`t$Relative"
    }
    $Utf8 = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText((Join-Path $DeckOut 'payload\RUNTIME-SHA256SUMS.txt'),(($Hashes -join "`n") + "`n"),$Utf8)
    [IO.File]::WriteAllText((Join-Path $DeckOut 'payload\VERSION.txt'),"Artur Edition $ReleaseVersion v$ModVersion protocol $Protocol SDK $SDKVersion`n",$Utf8)
    New-Item -ItemType Directory -Force $OutputDirectory | Out-Null
    $Output = Join-Path $OutputDirectory $ZipName
    if (Test-Path $Output) { Remove-Item -LiteralPath $Output -Force }
    $Archive = [IO.Compression.ZipFile]::Open($Output,[IO.Compression.ZipArchiveMode]::Create)
    try {
       foreach ($File in @(Get-ChildItem -LiteralPath $Bundle -Recurse -File)) {
         $Relative = $File.FullName.Substring($Bundle.Length+1).Replace('\','/')
         [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Archive,$File.FullName,$Relative,[IO.Compression.CompressionLevel]::Optimal) | Out-Null
       }
    } finally { $Archive.Dispose() }
    $TestZip = [IO.Compression.ZipFile]::OpenRead($Output)
    try {
      $Names = @($TestZip.Entries | ForEach-Object {$_.FullName})
      foreach ($Required in @('steamdeck/install.sh','steamdeck/launch.sh','steamdeck/payload/Retail/mods/HitmanCoop.dll','steamdeck/payload/Retail/ZHMModSDK.dll','steamdeck/payload/RUNTIME-SHA256SUMS.txt','docs/steamdeck-installation.md')) {
        if ($Names -notcontains $Required) {throw "ZIP missing: $Required"}
      }
      Write-Output ("Validated {0} ZIP entries with normalized / separators." -f $Names.Count)
    } finally { $TestZip.Dispose() }
    $Hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Output).Hash.ToLowerInvariant()
    [IO.File]::WriteAllText("$Output.sha256","$Hash  $ZipName`n",$Utf8)
    Write-Output "Steam Deck experimental ZIP: $Output"
    Write-Output "SHA256: $Hash"
    Write-Output "The Windows game/install was not modified."
} finally {
    Remove-Item -LiteralPath $Stage -Recurse -Force -ErrorAction SilentlyContinue
}
