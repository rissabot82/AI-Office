param(
    [int]$ReviewAfterDays = 180,
    [int]$StaleAfterDays = 365
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryLearning.Common.ps1")

$Now = Get-Date
$Results = New-Object System.Collections.Generic.List[object]

foreach ($File in @(Get-AIOfficeAllMemoryFiles)) {
    $Record = Read-AIOfficeMemoryJson -Path $File.FullName

    if ($null -eq $Record) {
        continue
    }

    $Updated = [datetime]$Record.updated_at
    $AgeDays = ($Now - $Updated).TotalDays

    $Results.Add([pscustomobject]@{
        memory_id = [string]$Record.memory_id
        title = [string]$Record.title
        scope = [string]$Record.scope
        department = [string]$Record.department
        age_days = [math]::Round($AgeDays, 2)
        review_due = ($AgeDays -ge $ReviewAfterDays)
        stale = ($AgeDays -ge $StaleAfterDays)
        confidence = [double]$Record.confidence
        status = [string]$Record.status
    })
}

return @(
    $Results |
        Sort-Object stale, review_due, age_days -Descending
)
