param(
    [int]$OlderThanDays = 30,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeAutomation.Common.ps1")

$root = Get-AIOfficeAutomationRoot
Set-Location $root

$cutoff = (Get-Date).AddDays(-$OlderThanDays)
$sourceFolders = @(
    ".\workspace\automation\execution-log",
    ".\workspace\automation\archived-events"
)

$archiveRoot = ".\workspace\automation\archive"

if (-not (Test-Path -LiteralPath $archiveRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $archiveRoot -Force | Out-Null
}

$count = 0

foreach ($source in $sourceFolders) {
    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        continue
    }

    $destination = Join-Path $archiveRoot (Split-Path $source -Leaf)

    if (-not (Test-Path -LiteralPath $destination -PathType Container)) {
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
    }

    $files = @(
        Get-ChildItem `
            -LiteralPath $source `
            -Filter "*.json" `
            -File `
            -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff }
    )

    foreach ($file in $files) {
        $count++

        if ($WhatIf) {
            Write-Host (
                "[WHATIF] Archive " +
                $file.FullName
            )
        }
        else {
            Move-Item `
                -LiteralPath $file.FullName `
                -Destination (Join-Path $destination $file.Name) `
                -Force

            Write-Host (
                "[ARCHIVED] " +
                $file.Name
            ) -ForegroundColor Green
        }
    }
}

Write-Host (
    $count.ToString() +
    " automation file(s) selected for archive."
)
