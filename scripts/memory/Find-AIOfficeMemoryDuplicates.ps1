param(
    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][string]$Summary,
    [Parameter(Mandatory=$true)][string]$Scope,
    [string]$Department = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryRecall.Common.ps1")

$Matches = New-Object System.Collections.Generic.List[object]

foreach ($File in @(Get-AIOfficeAllMemoryFiles)) {
    $Record = Read-AIOfficeMemoryJson -Path $File.FullName

    if ($null -eq $Record) {
        continue
    }

    if ([string]$Record.scope -ne $Scope) {
        continue
    }

    if ($Scope -eq "department" -and
        [string]$Record.department -ne $Department) {
        continue
    }

    $TitleMatch = [string]$Record.title -eq $Title
    $SummaryMatch = [string]$Record.summary -eq $Summary

    if ($TitleMatch -or $SummaryMatch) {
        $Matches.Add([pscustomobject]@{
            memory_id = [string]$Record.memory_id
            title_match = $TitleMatch
            summary_match = $SummaryMatch
            scope = [string]$Record.scope
            department = [string]$Record.department
            confidence = [double]$Record.confidence
        })
    }
}

$Record = [ordered]@{
    duplicate_check_id = (
        "DUPMEM-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
    checked_at = (Get-Date).ToString("o")
    title = $Title
    summary = $Summary
    scope = $Scope
    department = $Department
    duplicate_count = $Matches.Count
    duplicates = @($Matches | ForEach-Object { $_ })
}

Write-AIOfficeMemoryJson `
    -Value $Record `
    -Path (
        ".\workspace\memory\duplicates\" +
        [string]$Record.duplicate_check_id +
        ".json"
    )

return [pscustomobject]$Record
