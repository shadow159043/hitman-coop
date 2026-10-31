# Isolated HITMAN 3.290.1.0 compatibility *build*, not an installer.
# Official ZHMModSDK v4.2.1 uses updated ZHitman5/ZActor/ZItem layouts.
# Do not copy this DLL into a live HITMAN installation without native-hook review.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Deps = Join-Path $Root '_deps-sdk421'
New-Item -ItemType Directory -Force -Path $Deps | Out-Null
$Assets = @(
    @{ Name='DevPkg-ZHMModSDK.zip'; Sha='d13a986b588588d6456743ba0f9746dea00b321a964b0269b98711597400e885'; Folder='devpkg' },
    @{ Name='ZHMModSDK-Release.zip'; Sha='3837c5e241532276173b2beff1e13cfa77e473b11afbe70bb826fcb442a6358c'; Folder='sdk-release' }
)
foreach ($Asset in $Assets) {
    $Zip = Join-Path $Deps $Asset.Name
    if (-not (Test-Path $Zip)) {
        $Url = "https://github.com/OrfeasZ/ZHMModSDK/releases/download/v4.2.1/$($Asset.Name)"
        Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Zip
    }
    $Actual = (Get-FileHash $Zip -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($Actual -ne $Asset.Sha) { throw "SDK checksum mismatch for $($Asset.Name)" }
    $Folder = Join-Path $Deps $Asset.Folder
    if (-not (Test-Path $Folder)) { Expand-Archive -Path $Zip -DestinationPath $Folder }
    Write-Host "Verified SDK v4.2.1 asset $($Asset.Name)"
}
$Dx = Join-Path $Root '_deps\directx-headers\DirectX-Headers-1.614.0'
if (-not (Test-Path (Join-Path $Dx 'include\directx\d3d12.h'))) {
    throw 'Missing DirectX-Headers v1.614.0; first run the original tools/fetch-sdk.ps1 in the isolated clone.'
}
$Cmake = 'C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'
if (-not (Test-Path $Cmake)) { throw 'Visual Studio 2026 CMake not installed at expected path' }
& $Cmake -S $Root -B (Join-Path $Root '_build-sdk421') -G 'Visual Studio 18 2026' -A x64 "-DZHMMODSDK_DEVPKG_DIR=$(Join-Path $Deps 'devpkg')" "-DDIRECTX_HEADERS_DIR=$Dx" -DCOOP_BUILD_TESTS=ON
if ($LASTEXITCODE -ne 0) { throw 'SDK 4.2.1 configure failed' }
& $Cmake --build (Join-Path $Root '_build-sdk421') --config RelWithDebInfo --parallel 6
if ($LASTEXITCODE -ne 0) { throw 'SDK 4.2.1 build failed' }
& (Join-Path $Root '_build-sdk421\core\RelWithDebInfo\coop_tests.exe')
if ($LASTEXITCODE -ne 0) { throw 'SDK 4.2.1 core tests failed' }
Write-Host 'Build/test only. No HITMAN game files were replaced.'
