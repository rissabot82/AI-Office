param(
    [ValidateSet(
        "global",
        "chief-of-staff",
        "department",
        "personal",
        "business",
        "shared"
    )]
    [string]$Scope = "shared",
    [string]$Department = "",
    [ValidateSet(
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
    )]
    [string]$MemoryType,
    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][string]$Summary,
    [Parameter(Mandatory=$true)][string]$ContentJson,
    [Parameter(Mandatory=$true)][string]$SourceJson,
    [double]$Confidence = 0.75,
    [string[]]$Tags = @(),
    [string[]]$Entities = @(),
    [string[]]$Projects = @()
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryRecall.Common.ps1")

$Root = Get-AIOfficeMemoryRoot
Set-Location $Root

if (-not (Test-AIOfficeMemoryScope -Scope $Scope -Department $Department)) {
    throw "Invalid memory scope or missing department."
}

if (-not (Test-AIOfficeMemoryType -MemoryType $MemoryType)) {
    throw "Invalid memory type: $MemoryType"
}

if ($Confidence -lt 0.0 -or $Confidence -gt 1.0) {
    throw "Confidence must be between 0.0 and 1.0."
}

try {
    $Content = $ContentJson | ConvertFrom-Json
}
catch {
    throw "ContentJson is invalid: $($_.Exception.Message)"
}

try {
    $Source = $SourceJson | ConvertFrom-Json
}
catch {
    throw "SourceJson is invalid: $($_.Exception.Message)"
}

$MemoryId = New-AIOfficeMemoryId
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    memory_id = $MemoryId
    scope = $Scope
    department = $Department
    memory_type = $MemoryType
    title = $Title
    summary = $Summary
    content = $Content
    source = $Source
    confidence = $Confidence
    status = "active"
    created_at = $Now
    updated_at = $Now
    last_accessed_at = $null
    access_count = 0
    tags = @($Tags)
    entities = @($Entities)
    projects = @($Projects)
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = "memory-engine"
            details = "Long-term memory record created."
        }
    )
}

$ScopePath = Get-AIOfficeMemoryScopePath `
    -Scope $Scope `
    -Department $Department

$Path = Join-Path $ScopePath ($MemoryId + ".json")

Write-AIOfficeMemoryJson -Value $Record -Path $Path

$Capture = [ordered]@{
    capture_id = New-AIOfficeMemoryCaptureId
    memory_id = $MemoryId
    capture_type = "manual"
    source_type = if ($null -ne $Source.PSObject.Properties["type"]) {
        [string]$Source.type
    }
    else {
        "manual"
    }
    created_at = $Now
}

Write-AIOfficeMemoryJson `
    -Value $Capture `
    -Path (
        ".\workspace\memory\captures\" +
        [string]$Capture.capture_id +
        ".json"
    )

& ".\scripts\memory\Update-AIOfficeMemoryIndex.ps1" |
    Out-Null

Write-Host "Long-term memory created: $MemoryId" -ForegroundColor Green

return [pscustomobject]$Record
