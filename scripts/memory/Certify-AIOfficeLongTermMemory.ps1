param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryLearning.Common.ps1")

$Root = Get-AIOfficeMemoryRoot
Set-Location $Root

$Checks = New-Object System.Collections.Generic.List[object]

function Add-MemoryCheck {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Details
    )

    $Checks.Add([ordered]@{
        name = $Name
        passed = $Passed
        details = $Details
    })
}

$JsonFiles = @(
    ".\config\memory\memory-policy.json",
    ".\config\memory\memory-capture-recall-policy.json",
    ".\config\memory\memory-learning-health-policy.json",
    ".\config\memory\release-manifest.json"
)

foreach ($Path in $JsonFiles) {
    try {
        Get-Content -LiteralPath $Path -Raw |
            ConvertFrom-Json |
            Out-Null

        Add-MemoryCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $true `
            -Details "Parsed successfully."
    }
    catch {
        Add-MemoryCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $false `
            -Details $_.Exception.Message
    }
}

$Scripts = @(
    ".\scripts\memory\AIOfficeMemory.Common.ps1",
    ".\scripts\memory\AIOfficeMemoryRecall.Common.ps1",
    ".\scripts\memory\AIOfficeMemoryLearning.Common.ps1",
    ".\scripts\memory\New-AIOfficeMemory.ps1",
    ".\scripts\memory\Search-AIOfficeMemory.ps1",
    ".\scripts\memory\Find-AIOfficeMemoryDuplicates.ps1",
    ".\scripts\memory\Find-AIOfficeRelatedMemory.ps1",
    ".\scripts\memory\New-AIOfficeMemoryContextPacket.ps1",
    ".\scripts\memory\Add-AIOfficeMemoryFeedback.ps1",
    ".\scripts\memory\Find-AIOfficeStaleMemory.ps1",
    ".\scripts\memory\Find-AIOfficeMemoryConflicts.ps1",
    ".\scripts\memory\Get-AIOfficeMemoryHealthReport.ps1",
    ".\scripts\memory\Certify-AIOfficeLongTermMemory.ps1",
    ".\scripts\memory\Test-AIOfficeLongTermMemory.ps1",
    ".\scripts\memory\Publish-AIOfficeLongTermMemoryRelease.ps1"
)

foreach ($Path in $Scripts) {
    $Exists = Test-Path -LiteralPath $Path -PathType Leaf

    Add-MemoryCheck `
        -Name ("Script exists: " + $Path) `
        -Passed $Exists `
        -Details $(if ($Exists) { "Found." } else { "Missing." })
}

$MemoryIds = New-Object System.Collections.Generic.List[string]
$PacketId = ""

try {
    $MemoryOne = & ".\scripts\memory\New-AIOfficeMemory.ps1" `
        -Scope "business" `
        -MemoryType "fact" `
        -Title "Certification memory one" `
        -Summary "Primary certification fact." `
        -ContentJson '{"value":"one"}' `
        -SourceJson '{"type":"certification"}' `
        -Confidence 0.75 `
        -Tags @("certification") `
        -Entities @("AI Office") `
        -Projects @("Long-Term Memory")

    $MemoryTwo = & ".\scripts\memory\New-AIOfficeMemory.ps1" `
        -Scope "shared" `
        -MemoryType "fact" `
        -Title "Certification memory two" `
        -Summary "Secondary certification fact." `
        -ContentJson '{"value":"two"}' `
        -SourceJson '{"type":"certification"}' `
        -Confidence 0.80 `
        -Tags @("certification") `
        -Entities @("AI Office") `
        -Projects @("Long-Term Memory")

    $MemoryIds.Add([string]$MemoryOne.memory_id)
    $MemoryIds.Add([string]$MemoryTwo.memory_id)

    Add-MemoryCheck `
        -Name "Memory creation" `
        -Passed ($MemoryIds.Count -eq 2) `
        -Details "Created two certification memories."

    $Search = @(
        & ".\scripts\memory\Search-AIOfficeMemory.ps1" `
            -Query "certification" `
            -Limit 10
    )

    Add-MemoryCheck `
        -Name "Memory search" `
        -Passed ($Search.Count -ge 2) `
        -Details ($Search.Count.ToString() + " result(s)")

    $Packet = & ".\scripts\memory\New-AIOfficeMemoryContextPacket.ps1" `
        -Query "certification" `
        -RequestedBy "chief-of-staff" `
        -Limit 10

    $PacketId = [string]$Packet.context_packet_id

    Add-MemoryCheck `
        -Name "Context packet" `
        -Passed ([int]$Packet.memory_count -ge 2) `
        -Details $PacketId

    $Feedback = & ".\scripts\memory\Add-AIOfficeMemoryFeedback.ps1" `
        -MemoryId ([string]$MemoryIds[0]) `
        -FeedbackType "promote" `
        -Summary "Certification promotion test."

    Add-MemoryCheck `
        -Name "Feedback and promotion" `
        -Passed ([double]$Feedback.confidence_after -gt
            [double]$Feedback.confidence_before) `
        -Details ([string]$Feedback.feedback_id)

    $Health = & ".\scripts\memory\Get-AIOfficeMemoryHealthReport.ps1"

    Add-MemoryCheck `
        -Name "Memory health report" `
        -Passed ($null -ne $Health) `
        -Details ([string]$Health.report_id)
}
catch {
    Add-MemoryCheck `
        -Name "Offline end-to-end Long-Term Memory workflow" `
        -Passed $false `
        -Details $_.Exception.Message
}

foreach ($MemoryId in $MemoryIds) {
    $File = Find-AIOfficeMemoryFile -MemoryId $MemoryId

    if ($null -ne $File -and
        (Test-Path -LiteralPath $File.FullName -PathType Leaf)) {
        Remove-Item -LiteralPath $File.FullName -Force
    }
}

if ($PacketId) {
    $Path = ".\workspace\memory\context-packets\$PacketId.json"

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

foreach ($Folder in @(
    ".\workspace\memory\captures",
    ".\workspace\memory\feedback"
)) {
    Get-ChildItem `
        -LiteralPath $Folder `
        -Filter "*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        ForEach-Object {
            $Record = Read-AIOfficeMemoryJson -Path $_.FullName

            if ($null -ne $Record -and
                $MemoryIds -contains [string]$Record.memory_id) {
                Remove-Item -LiteralPath $_.FullName -Force
            }
        }
}

Get-ChildItem `
    -LiteralPath ".\workspace\memory\conflicts" `
    -Filter "MCF-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        $Record = Read-AIOfficeMemoryJson -Path $_.FullName

        if ($null -ne $Record -and
            (@($Record.memory_ids) | Where-Object {
                $MemoryIds -contains [string]$_
            }).Count -gt 0) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

& ".\scripts\memory\Update-AIOfficeMemoryIndex.ps1" |
    Out-Null

$PassedCount = @(
    $Checks | Where-Object { $_.passed -eq $true }
).Count

$FailedCount = @(
    $Checks | Where-Object { $_.passed -eq $false }
).Count

$Status = if ($FailedCount -eq 0) {
    "certified"
}
else {
    "failed"
}

$CertificationId = (
    "CERT-MEM-" +
    (Get-Date).ToString("yyyyMMdd-HHmmss")
)

$Certification = [ordered]@{
    certification_id = $CertificationId
    version = "1.3.0"
    certified_at = (Get-Date).ToString("o")
    status = $Status
    passed_checks = $PassedCount
    failed_checks = $FailedCount
    checks = @($Checks | ForEach-Object { $_ })
}

Write-AIOfficeMemoryJson `
    -Value $Certification `
    -Path (
        ".\workspace\memory\certification\" +
        $CertificationId +
        ".json"
    )

Write-Host (
    "Long-Term Memory certification: " +
    $Status +
    " | " +
    $PassedCount.ToString() +
    " passed, " +
    $FailedCount.ToString() +
    " failed"
) -ForegroundColor $(if ($FailedCount -eq 0) { "Green" } else { "Red" })

return [pscustomobject]$Certification
