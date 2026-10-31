# Run only after creating an EMPTY, PRIVATE repository under this GitHub account.
param([string]$Repository = "https://github.com/shadow159043/hitman-coop-artur.git")
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Push-Location $root
try {
    if ((git status --porcelain)) { throw "Commit local changes first; working tree is not clean." }
    git ls-remote $Repository *> $null
    if ($LASTEXITCODE -ne 0) { throw "Private GitHub repository inaccessible. Create it and sign in to git first: $Repository" }
    $remote = git remote get-url artur-backup 2>$null
    if ($LASTEXITCODE -eq 0) {
        if ($remote -ne $Repository) { throw "Existing artur-backup points elsewhere: $remote" }
    } else {
        git remote add artur-backup $Repository
    }
    git push -u artur-backup "fix/3290-remote-player:main"
    if ($LASTEXITCODE -ne 0) { throw "Pushing main failed." }
    git push artur-backup --tags
    if ($LASTEXITCODE -ne 0) { throw "Pushing tags failed." }
    Write-Host "Source and Git history pushed. Upload experimental release assets separately."
}
finally { Pop-Location }
