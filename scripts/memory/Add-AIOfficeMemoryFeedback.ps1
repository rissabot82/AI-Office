param(
    [Parameter(Mandatory=$true)][string]$MemoryId,
    [ValidateSet("confirm","correct","reject","promote","demote")]
    [string]$FeedbackType,
    [Parameter(Mandatory=$true)][string]$Summary,
    [string]$CreatedBy = "chief-of-staff"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryLearning.Common.ps1")

$File = Find-AIOfficeMemoryFile -MemoryId $MemoryId

if ($null -eq $File) {
    throw "Memory record not found: $MemoryId"
}

$Record = Read-AIOfficeMemoryJson -Path $File.FullName
$Policy = Get-AIOfficeMemoryLearningPolicy

$Before = [double]$Record.confidence
$Adjustment = [double]$Policy.confidence_adjustments.$FeedbackType
$After = [math]::Min(1.0, [math]::Max(0.0, $Before + $Adjustment))

$Record.confidence = $After
$Record.updated_at = (Get-Date).ToString("o")

if ($After -ge [double]$Policy.status_rules.promote_at) {
    $Record.status = "promoted"
}
elseif ($After -lt [double]$Policy.status_rules.archive_below) {
    $Record.status = "archived"
}
elseif ($After -lt [double]$Policy.status_rules.review_below) {
    $Record.status = "review_required"
}
else {
    $Record.status = "active"
}

$History = New-Object System.Collections.Generic.List[object]

foreach ($Entry in @($Record.history)) {
    $History.Add($Entry)
}

$History.Add([ordered]@{
    timestamp = (Get-Date).ToString("o")
    action = $FeedbackType
    actor = $CreatedBy
    details = $Summary
})

$Record.history = @($History | ForEach-Object { $_ })

Write-AIOfficeMemoryJson -Value $Record -Path $File.FullName

$FeedbackRecord = [ordered]@{
    feedback_id = New-AIOfficeMemoryFeedbackId
    memory_id = $MemoryId
    feedback_type = $FeedbackType
    summary = $Summary
    confidence_before = $Before
    confidence_after = $After
    status_after = [string]$Record.status
    created_at = (Get-Date).ToString("o")
    created_by = $CreatedBy
}

Write-AIOfficeMemoryJson `
    -Value $FeedbackRecord `
    -Path (
        ".\workspace\memory\feedback\" +
        [string]$FeedbackRecord.feedback_id +
        ".json"
    )

& ".\scripts\memory\Update-AIOfficeMemoryIndex.ps1" |
    Out-Null

Write-Host (
    "Memory feedback recorded: " +
    [string]$FeedbackRecord.feedback_id
) -ForegroundColor Green

return [pscustomobject]$FeedbackRecord
