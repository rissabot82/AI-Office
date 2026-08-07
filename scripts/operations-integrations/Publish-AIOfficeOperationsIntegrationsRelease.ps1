param(
    [switch]$SkipGit
)

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$Certification = & "E:\AI\AI-Office\scripts\operations-integrations\Certify-AIOfficeOperationsIntegrations.ps1"

if ([string]$Certification.status -ne "certified") {
    throw "AI Office v1.9 Operations and Integrations certification failed."
}

$ManifestPath = "E:\AI\AI-Office\config\operations-integrations\release-manifest.json"
$Manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$Manifest.status = "released"
$Manifest | Add-Member -NotePropertyName "released_at" -NotePropertyValue (Get-Date).ToString("o") -Force
$Manifest | Add-Member -NotePropertyName "certification_id" -NotePropertyValue ([string]$Certification.certification_id) -Force
$Manifest | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath $ManifestPath -Encoding UTF8

$VersionPath = "E:\AI\AI-Office\config\identity\version.json"
if (Test-Path -LiteralPath $VersionPath -PathType Leaf) {
    $Version = Get-Content -LiteralPath $VersionPath -Raw | ConvertFrom-Json
    $Version.version = "1.9.0"
    $Version.release_name = "Operations and Integrations"
    $Version.status = "released"
    $Version | Add-Member -NotePropertyName "released_at" -NotePropertyValue (Get-Date).ToString("o") -Force
    $Version.next_planned_milestone = "2.0 Autonomous AI Enterprise"
    $Version | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath $VersionPath -Encoding UTF8
}

& "E:\AI\AI-Office\scripts\operations-integrations\New-AIOfficeOperationsDashboardSnapshot.ps1" | Out-Null

if (-not $SkipGit) {
    git add --all

    $Pending = git status --porcelain
    if (-not [string]::IsNullOrWhiteSpace(($Pending | Out-String))) {
        git commit -m "Release AI Office v1.9 Operations and Integrations"
        if ($LASTEXITCODE -ne 0) {
            throw "Git commit failed."
        }
    }
    else {
        Write-Host "No Git changes to commit." -ForegroundColor Yellow
    }

    $TagExists = git tag --list "v1.9.0"
    if ([string]::IsNullOrWhiteSpace(($TagExists | Out-String))) {
        git tag -a v1.9.0 -m "AI Office v1.9 Operations and Integrations"
        if ($LASTEXITCODE -ne 0) {
            throw "Git tag creation failed."
        }
        Write-Host "Created Git tag v1.9.0." -ForegroundColor Green
    }
    else {
        Write-Host "Git tag v1.9.0 already exists." -ForegroundColor Yellow
    }

    git push origin main
    if ($LASTEXITCODE -ne 0) {
        throw "Git push failed."
    }

    git push origin v1.9.0
    if ($LASTEXITCODE -ne 0) {
        throw "Git tag push failed."
    }
}

Write-Host ""
Write-Host "AI Office v1.9 Operations and Integrations released." -ForegroundColor Green
return $Certification
