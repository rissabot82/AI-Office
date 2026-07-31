param(
    [Parameter(Mandatory=$true)][string]$SourceType,
    [Parameter(Mandatory=$true)][string]$SourcePath,
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
    [string]$MemoryType = "reference",
    [string]$Title = "",
    [string]$Summary = "",
    [double]$Confidence = 0.75
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
    throw "Source file not found: $SourcePath"
}

try {
    $SourceRecord = Get-Content -LiteralPath $SourcePath -Raw |
        ConvertFrom-Json
}
catch {
    throw "Source file is not valid JSON: $($_.Exception.Message)"
}

if ([string]::IsNullOrWhiteSpace($Title)) {
    foreach ($PropertyName in @("title","subject","name","objective","summary")) {
        if ($null -ne $SourceRecord.PSObject.Properties[$PropertyName] -and
            -not [string]::IsNullOrWhiteSpace([string]$SourceRecord.$PropertyName)) {
            $Title = [string]$SourceRecord.$PropertyName
            break
        }
    }
}

if ([string]::IsNullOrWhiteSpace($Title)) {
    $Title = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath)
}

if ([string]::IsNullOrWhiteSpace($Summary)) {
    foreach ($PropertyName in @("summary","objective","description","decision","result_summary")) {
        if ($null -ne $SourceRecord.PSObject.Properties[$PropertyName] -and
            -not [string]::IsNullOrWhiteSpace([string]$SourceRecord.$PropertyName)) {
            $Summary = [string]$SourceRecord.$PropertyName
            break
        }
    }
}

if ([string]::IsNullOrWhiteSpace($Summary)) {
    $Summary = "Memory captured from $SourceType source."
}

$Source = [ordered]@{
    type = $SourceType
    path = (Resolve-Path -LiteralPath $SourcePath).Path
    captured_at = (Get-Date).ToString("o")
}

return & ".\scripts\memory\New-AIOfficeMemory.ps1" `
    -Scope $Scope `
    -Department $Department `
    -MemoryType $MemoryType `
    -Title $Title `
    -Summary $Summary `
    -ContentJson ($SourceRecord | ConvertTo-Json -Depth 50 -Compress) `
    -SourceJson ($Source | ConvertTo-Json -Depth 10 -Compress) `
    -Confidence $Confidence
