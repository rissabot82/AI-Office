param(
    [switch]$Push
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git is not installed or not available on PATH."
}

git status --short
git add .

$Pending = git status --porcelain

if ([string]::IsNullOrWhiteSpace(($Pending | Out-String))) {
    Write-Host "No changes to commit." -ForegroundColor Yellow
}
else {
    git commit -m "Release AI Office v1.4 Autonomous Workflows"

    if ($LASTEXITCODE -ne 0) {
        throw "Git commit failed."
    }
}

$TagExists = git tag --list "v1.4.0"

if ([string]::IsNullOrWhiteSpace(($TagExists | Out-String))) {
    git tag -a v1.4.0 -m "AI Office v1.4 Autonomous Workflows"

    if ($LASTEXITCODE -ne 0) {
        throw "Git tag creation failed."
    }

    Write-Host "Created tag v1.4.0." -ForegroundColor Green
}
else {
    Write-Host "Tag v1.4.0 already exists." -ForegroundColor Yellow
}

if ($Push) {
    git push origin main --tags

    if ($LASTEXITCODE -ne 0) {
        throw "Git push failed."
    }
}

git status
Write-Host "AI Office v1.4 Git checkpoint complete." -ForegroundColor Green
