# Generate the signed Artur Edition update channel from the exact Windows release ZIP.
# Execute on the release PC after CI has passed: ./tools/make-update-feed.ps1 -Zip <release ZIP>
# The private signing key NEVER leaves .signing/ on this machine.
param(
    [Parameter(Mandatory=$true)][string]$Zip,
    [string]$Version = "0.14.1",
    [string]$OutDir = (Join-Path $PSScriptRoot "..\_dist\update-$Version")
)
$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Zip = (Resolve-Path $Zip).Path
$Key = Join-Path $Root ".signing\update-key.blob"
if (-not (Test-Path $Key)) { throw "Artur Edition signing key is missing: .signing/update-key.blob" }
# Check that the key used for signing matches the one built into all released DLLs.
$Public = & powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File (Join-Path $Root "tools\update-key.ps1")
if ($LASTEXITCODE -ne 0) { throw "Cannot read fork signing public key" }
$Source = Get-Content (Join-Path $Root "plugin\Src\UpdateKey.h") -Raw
$Expected = @([regex]::Matches(($Public -join " "), '0x[0-9a-fA-F]{2}') | ForEach-Object { $_.Value.ToLowerInvariant() })
$Actual = @([regex]::Matches($Source, '0x[0-9a-fA-F]{2}') | ForEach-Object { $_.Value.ToLowerInvariant() })
if ($Expected.Count -ne 72 -or (Compare-Object $Expected $Actual -SyncWindow 0)) { throw "Fork signing key does NOT match UpdateKey.h" }

$Temporary = Join-Path $env:TEMP ("artur-update-feed-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force $Temporary | Out-Null
try {
    Expand-Archive -LiteralPath $Zip -DestinationPath $Temporary -Force
    $Package = Join-Path $Temporary "HitmanCoop-Artur-$Version"
    if (-not (Test-Path $Package)) { throw "Release zip is not the expected $Version package" }
    New-Item -ItemType Directory -Force $OutDir | Out-Null
    $OutDir = (Resolve-Path $OutDir).Path
    $Notes = "HITMAN Co-op Artur Edition $Version. Fork-owned signed auto-updates, safer update checks and Linux/Steam Deck payload. Both players need the same edition. Restart HITMAN to activate an update."
    $Jobs = @(
        @{ Source = "files"; Game = "3.290"; Into = ""; Manifest = "update.txt"; Base = "https://raw.githubusercontent.com/shadow159043/hitman-coop/updates/" },
        @{ Source = "files-3.280"; Game = "3.280"; Into = "game-3.280"; Manifest = "update-3.280.txt"; Base = "https://raw.githubusercontent.com/shadow159043/hitman-coop/updates/game-3.280/" }
    )
    foreach ($Job in $Jobs) {
        $SourceDir = Join-Path $Package $Job.Source
        if (-not (Test-Path $SourceDir)) { throw "Missing game $($Job.Game) in package" }
        $DestDir = if ($Job.Into) { Join-Path $OutDir $Job.Into } else { $OutDir }
        New-Item -ItemType Directory -Force $DestDir | Out-Null
        $Lines = @("version $Version", "base $($Job.Base)")
        $Used = @{}
        $Files = @(Get-ChildItem -LiteralPath $SourceDir -File -Recurse)
        if ($Files.Count -lt 4) { throw "Missing mod files for $($Job.Game)" }
        foreach ($File in $Files) {
            $Rel = $File.FullName.Substring($SourceDir.Length + 1).Replace("\", "/")
            if ($Rel -notmatch '^[A-Za-z0-9_./-]+$' -or $Rel.Contains("..")) { throw "Invalid manifest file path: $Rel" }
            if ($Used.ContainsKey($File.Name)) { throw "Colliding update filename: $($File.Name)" }
            $Used[$File.Name] = $true
            Copy-Item -LiteralPath $File.FullName -Destination (Join-Path $DestDir $File.Name) -Force
            $Hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $File.FullName).Hash.ToLowerInvariant()
            $Lines += "file $Rel $($File.Length) $Hash"
        }
        $Lines += "notes"
        $Text = ($Lines -join "`n") + "`n" + $Notes + "`n"
        $ManifestPath = Join-Path $OutDir $Job.Manifest
        [System.IO.File]::WriteAllText($ManifestPath, $Text, [System.Text.UTF8Encoding]::new($false))
        & powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File (Join-Path $Root "tools\update-key.ps1") -Sign $ManifestPath | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Cannot sign $($Job.Manifest)" }
        & powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File (Join-Path $Root "tools\update-key.ps1") -Verify $ManifestPath | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Invalid signature: $($Job.Manifest)" }
        Write-Output ("SIGNED $($Job.Game) " + $Job.Manifest + " + " + $Files.Count + " verified files")
    }
    Write-Output "Signed update branch contents ready: $OutDir"
} finally {
    Remove-Item -LiteralPath $Temporary -Recurse -Force -ErrorAction SilentlyContinue
}
