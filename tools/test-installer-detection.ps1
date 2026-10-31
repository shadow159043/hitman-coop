# Isolated discovery tests: no real game files modified and no launcher account access.
$ErrorActionPreference = "Stop"
$Source = Join-Path $PSScriptRoot "..\installer\installer.ps1"
$Tokens = $null
$Errors = $null
$Ast = [Management.Automation.Language.Parser]::ParseFile($Source, [ref]$Tokens, [ref]$Errors)
if ($Errors.Count) { throw "Installer source has syntax errors: $($Errors[0])" }
$Names = @("Test-GameDir", "Get-UniquePaths", "Find-SteamGames", "Find-EpicGames")
$Functions = @($Ast.FindAll({ param($Node) $Node -is [Management.Automation.Language.FunctionDefinitionAst] -and $Node.Name -in $Names }, $true))
if ($Functions.Count -ne $Names.Count) { throw "Could not load all detection functions" }
foreach ($Function in $Functions) { . ([scriptblock]::Create($Function.Extent.Text)) }

$Temp = Join-Path ([IO.Path]::GetTempPath()) ("HitmanCoop-AutoDetect-Test-" + [guid]::NewGuid().ToString("N"))
New-Item $Temp -ItemType Directory -Force | Out-Null
try {
    function MakeFakeGame([string]$Folder) {
        $Retail = Join-Path $Folder "Retail"
        New-Item $Retail -ItemType Directory -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $Retail "HITMAN3.exe"), [byte[]]@(0))
    }
    function AssertDetected([string[]]$Actual, [string]$Expected, [string]$TestName) {
        if (@($Actual | Where-Object { $_.TrimEnd('\') -ieq $Expected.TrimEnd('\') }).Count -ne 1) {
            throw "$TestName failed. Expected $Expected. Got: $($Actual -join ' | ')"
        }
        Write-Output "PASS: $TestName"
    }

    $SteamRoot = Join-Path $Temp "Steam"
    $ExtraLib = Join-Path $Temp "Library On D"
    $SteamGame = Join-Path $ExtraLib "steamapps\common\Custom HITMAN Folder"
    MakeFakeGame $SteamGame
    $Vdf = Join-Path $SteamRoot "steamapps\libraryfolders.vdf"
    New-Item (Split-Path $Vdf -Parent) -ItemType Directory -Force | Out-Null
    $Escaped = $ExtraLib.Replace('\', '\\')
    Set-Content -LiteralPath $Vdf -Value ('"libraryfolders" { "1" { "path" "' + $Escaped + '" } }')
    Set-Content -LiteralPath (Join-Path $ExtraLib "steamapps\appmanifest_1659040.acf") -Value '"AppState" { "appid" "1659040" "installdir" "Custom HITMAN Folder" }'
    $Detected = @(Find-SteamGames -SteamRoots @($SteamRoot))
    AssertDetected $Detected $SteamGame "Steam custom library + appmanifest"
    if ($Detected.Count -ne 1) { throw "Steam returned unexpected duplicate installs" }

    $DefaultGame = Join-Path $SteamRoot "steamapps\common\HITMAN 3"
    MakeFakeGame $DefaultGame
    $Detected = @(Find-SteamGames -SteamRoots @($SteamRoot))
    AssertDetected $Detected $DefaultGame "Steam default library fallback"
    AssertDetected $Detected $SteamGame "Steam secondary library still detected"

    $EpicDir = Join-Path $Temp "EpicManifestFolder"
    New-Item $EpicDir -ItemType Directory -Force | Out-Null
    $EpicGame = Join-Path $Temp "Epic Games\HITMAN World of Assassination"
    MakeFakeGame $EpicGame
    $EpicItem = @{DisplayName="HITMAN World of Assassination"; InstallLocation=$EpicGame; AppName="Hitman"} | ConvertTo-Json
    Set-Content -LiteralPath (Join-Path $EpicDir "Hitman.item") -Value $EpicItem
    Set-Content -LiteralPath (Join-Path $EpicDir "broken.item") -Value '{bad-json'
    $OtherDb = Join-Path $Temp "not-present.dat"
    $Detected = @(Find-EpicGames -ManifestsDirectory $EpicDir -LauncherInstalledFile $OtherDb)
    AssertDetected $Detected $EpicGame "Epic .item manifest and broken-manifest tolerance"

    $EpicDbGame = Join-Path $Temp "EpicCustom\HitmanIII"
    MakeFakeGame $EpicDbGame
    $Database = @{InstallationList=@(@{AppName="HITMAN 3";InstallLocation=$EpicDbGame})} | ConvertTo-Json -Depth 4
    $DatabasePath = Join-Path $Temp "LauncherInstalled.dat"
    Set-Content -LiteralPath $DatabasePath -Value $Database
    $Detected = @(Find-EpicGames -ManifestsDirectory $EpicDir -LauncherInstalledFile $DatabasePath)
    AssertDetected $Detected $EpicDbGame "Epic LauncherInstalled.dat"
    AssertDetected $Detected $EpicGame "Epic manifest retained alongside database"

    # Stale launcher records must not count as an installed game.
    Remove-Item -LiteralPath (Join-Path $EpicDbGame "Retail\HITMAN3.exe") -Force
    $Detected = @(Find-EpicGames -ManifestsDirectory $EpicDir -LauncherInstalledFile $DatabasePath)
    if (@($Detected | Where-Object { $_ -ieq $EpicDbGame }).Count -ne 0) {throw "Epic returned a missing executable"}
    Write-Output "PASS: Stale Epic entry ignored"

    Write-Output "PASS: All synthetic Steam and Epic discovery checks."
}
finally {
    Remove-Item $Temp -Recurse -Force -ErrorAction SilentlyContinue
}