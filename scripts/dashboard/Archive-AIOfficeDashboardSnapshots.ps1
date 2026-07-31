param(
    [int]$OlderThanDays = 90,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDashboard.Common.ps1")

$root = Get-AIOfficeDashboardRoot
Set-Location $root

$cutoff = (Get-Date).AddDays(-$OlderThanDays)
$snapshotFolder = ".\workspace\dashboard\snapshots"
$archiveFolder = ".\workspace\dashboard\archive"

if (-not (Test-Path -LiteralPath $archiveFolder)) {
    New-Item -ItemType Directory -Path $archiveFolder -Force |
        Out-Null
}

$candidates = @(
    Get-ChildItem `
        -LiteralPath $snapshotFolder `
        -Filter "DSH-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoff }
)

foreach ($file in $candidates) {
    $destination = Join-Path $archiveFolder $file.Name

    if ($WhatIf) {
        Write-Host (
            "[WHATIF] Move " +
            $file.FullName +
            " to " +
            $destination
        )
    }
    else {
        Move-Item `
            -LiteralPath $file.FullName `
            -Destination $destination `
            -Force

        Write-Host (
            "[ARCHIVED] " +
            $file.Name
        ) -ForegroundColor Green
    }
}

if (-not $WhatIf) {
    & ".\scripts\dashboard\Update-AIOfficeDashboardIndex.ps1" |
        Out-Null
}

Write-Host (
    $candidates.Count.ToString() +
    " snapshot(s) selected for archive."
)
