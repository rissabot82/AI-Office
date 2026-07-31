param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryLearning.Common.ps1")

$Root = Get-AIOfficeMemoryRoot
Set-Location $Root

$Index = & ".\scripts\memory\Update-AIOfficeMemoryIndex.ps1"
$Policy = Get-AIOfficeMemoryLearningPolicy

$Stale = @(
    & ".\scripts\memory\Find-AIOfficeStaleMemory.ps1" `
        -ReviewAfterDays ([int]$Policy.staleness.review_after_days) `
        -StaleAfterDays ([int]$Policy.staleness.stale_after_days)
)

$Conflicts = @(
    & ".\scripts\memory\Find-AIOfficeMemoryConflicts.ps1"
)

$LowConfidence = @(
    foreach ($File in @(Get-AIOfficeAllMemoryFiles)) {
        $Record = Read-AIOfficeMemoryJson -Path $File.FullName

        if ($null -ne $Record -and
            [double]$Record.confidence -lt
            [double]$Policy.status_rules.review_below) {
            [pscustomobject]@{
                memory_id = [string]$Record.memory_id
                title = [string]$Record.title
                confidence = [double]$Record.confidence
                status = [string]$Record.status
            }
        }
    }
)

$HealthStatus = if (
    @($Stale | Where-Object { $_.stale }).Count -gt 0 -or
    $Conflicts.Count -gt 0 -or
    $LowConfidence.Count -gt 0
) {
    "attention_required"
}
else {
    "healthy"
}

$Report = [ordered]@{
    report_id = (
        "MEMHEALTH-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss")
    )
    generated_at = (Get-Date).ToString("o")
    status = $HealthStatus
    total_memory_count = [int]$Index.total_memory_count
    active_memory_count = [int]$Index.active_memory_count
    archived_memory_count = [int]$Index.archived_memory_count
    review_due_count = @(
        $Stale | Where-Object { $_.review_due }
    ).Count
    stale_count = @(
        $Stale | Where-Object { $_.stale }
    ).Count
    low_confidence_count = $LowConfidence.Count
    conflict_count = $Conflicts.Count
    scope_counts = $Index.scope_counts
    type_counts = $Index.type_counts
    department_counts = $Index.department_counts
    stale_memories = $Stale
    low_confidence_memories = $LowConfidence
    conflicts = $Conflicts
}

Write-AIOfficeMemoryJson `
    -Value $Report `
    -Path (
        ".\workspace\memory\health\" +
        [string]$Report.report_id +
        ".json"
    )

Write-Host (
    "Memory health report created: " +
    [string]$Report.report_id
) -ForegroundColor Green

return [pscustomobject]$Report
