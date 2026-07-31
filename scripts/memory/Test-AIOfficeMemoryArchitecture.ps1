param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.3 Part A Long-Term Memory Architecture..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\memory\memory-policy.json",
    ".\config\memory\memory-record-schema.json",
    ".\config\memory\memory-index-schema.json",
    ".\config\memory\memory-scope-schema.json",
    ".\workspace\templates\long-term-memory-record-template.json",
    ".\workspace\memory\indexes\memory-index.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw |
            ConvertFrom-Json |
            Out-Null

        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: " + $File)
    }
}

$Scripts = @(
    ".\scripts\memory\AIOfficeMemory.Common.ps1",
    ".\scripts\memory\Update-AIOfficeMemoryIndex.ps1",
    ".\scripts\memory\Show-AIOfficeMemoryStatus.ps1",
    ".\scripts\memory\Test-AIOfficeMemoryArchitecture.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING    ] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: " + $Script)
    }
}

try {
    . ".\scripts\memory\AIOfficeMemory.Common.ps1"
$ScopeChecks = @(
    (Test-AIOfficeMemoryScope -Scope "global")
    (Test-AIOfficeMemoryScope -Scope "chief-of-staff")
    (Test-AIOfficeMemoryScope -Scope "personal")
    (Test-AIOfficeMemoryScope -Scope "business")
    (Test-AIOfficeMemoryScope -Scope "shared")
    (Test-AIOfficeMemoryScope -Scope "department" -Department "marketing")
)
    if ($ScopeChecks -contains $false) {
        throw "One or more memory scopes failed validation."
    }

    Write-Host "[SCOPE OK   ] Memory scope validation passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[SCOPE ERR  ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Scope validation failed: " + $_.Exception.Message)
}

try {
    . ".\scripts\memory\AIOfficeMemory.Common.ps1"

    foreach ($MemoryType in @(
        "fact",
        "preference",
        "decision",
        "goal",
        "project",
        "relationship",
        "procedure",
        "lesson",
        "event",
        "metric",
        "constraint",
        "reference"
    )) {
        if (-not (Test-AIOfficeMemoryType -MemoryType $MemoryType)) {
            throw "Memory type failed validation: $MemoryType"
        }
    }

    Write-Host "[TYPE OK    ] Memory type validation passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[TYPE ERR   ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Memory type validation failed: " + $_.Exception.Message)
}

try {
    $Index = & ".\scripts\memory\Update-AIOfficeMemoryIndex.ps1"

    if ($null -eq $Index -or
        [int]$Index.total_memory_count -ne 0 -or
        [string]$Index.status -ne "ready") {
        throw "Memory index did not initialize correctly."
    }

    Write-Host "[INDEX OK   ] Empty memory index initialized." `
        -ForegroundColor Green
}
catch {
    Write-Host "[INDEX ERR  ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Memory index validation failed: " + $_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Long-Term Memory architecture error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.3 Part A Long-Term Memory Architecture checks passed." `
    -ForegroundColor Green

