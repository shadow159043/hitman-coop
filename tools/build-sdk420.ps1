# Isolated HITMAN 3.290.1.0 compatibility *build*, not an installer.
# Official ZHMModSDK v4.2.0 uses updated ZHitman5/ZActor/ZItem layouts.
# Do not copy this DLL into a live HITMAN installation without native-hook review.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Deps = Join-Path $Root '_deps-sdk420'
New-Item -ItemType Directory -Force -Path $Deps | Out-Null
$Assets = @(
    @{ Name='DevPkg-ZHMModSDK.zip'; Sha='f146a872ec612e87f5aaa487b6cc8b88f1597643a02c9c93f8953ade6f1dda4a'; Folder='devpkg' },
    @{ Name='ZHMModSDK-Release.zip'; Sha='188bcfb7fd0b769156b82a589eff2c243f159d8800dad2c6eb8da017090af8f8'; Folder='sdk-release' }
)
foreach ($Asset in $Assets) {
    $Zip = Join-Path $Deps $Asset.Name
    if (-not (Test-Path $Zip)) {
        $Url = "https://github.com/OrfeasZ/ZHMModSDK/releases/download/v4.2.0/$($Asset.Name)"
        Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Zip
    }
    $Actual = (Get-FileHash $Zip -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($Actual -ne $Asset.Sha) { throw "SDK checksum mismatch for $($Asset.Name)" }
    $Folder = Join-Path $Deps $Asset.Folder
    if (-not (Test-Path $Folder)) { Expand-Archive -Path $Zip -DestinationPath $Folder }
    Write-Host "Verified SDK v4.2.0 asset $($Asset.Name)"
}
$Dx = Join-Path $Root '_deps\directx-headers\DirectX-Headers-1.614.0'
if (-not (Test-Path (Join-Path $Dx 'include\directx\d3d12.h'))) {
    throw 'Missing DirectX-Headers v1.614.0; first run the original tools/fetch-sdk.ps1 in the isolated clone.'
}
$Cmake = 'C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'
if (-not (Test-Path $Cmake)) { throw 'Visual Studio 2026 CMake not installed at expected path' }
& $Cmake -S $Root -B (Join-Path $Root '_build-sdk420') -G 'Visual Studio 18 2026' -A x64 "-DZHMMODSDK_DEVPKG_DIR=$(Join-Path $Deps 'devpkg')" "-DDIRECTX_HEADERS_DIR=$Dx" -DCOOP_BUILD_TESTS=ON
if ($LASTEXITCODE -ne 0) { throw 'SDK 4.2.0 configure failed' }
& $Cmake --build (Join-Path $Root '_build-sdk420') --config RelWithDebInfo --parallel 6
if ($LASTEXITCODE -ne 0) { throw 'SDK 4.2.0 build failed' }
& (Join-Path $Root '_build-sdk420\core\RelWithDebInfo\coop_tests.exe')
if ($LASTEXITCODE -ne 0) { throw 'SDK 4.2.0 core tests failed' }
Write-Host 'Build/test only. No HITMAN game files were replaced.'
