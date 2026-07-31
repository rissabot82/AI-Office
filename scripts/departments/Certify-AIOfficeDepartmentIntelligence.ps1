param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentKnowledge.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Checks = New-Object System.Collections.Generic.List[object]

function Add-DepartmentCheck {
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
    ".\config\departments\department-intelligence-policy.json",
    ".\config\departments\department-inbox-policy.json",
    ".\config\departments\department-execution-policy.json",
    ".\config\departments\department-knowledge-policy.json",
    ".\config\departments\release-manifest.json"
)

foreach ($Path in $JsonFiles) {
    try {
        Get-Content -LiteralPath $Path -Raw |
            ConvertFrom-Json |
            Out-Null

        Add-DepartmentCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $true `
            -Details "Parsed successfully."
    }
    catch {
        Add-DepartmentCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $false `
            -Details $_.Exception.Message
    }
}

$Scripts = @(
    ".\scripts\departments\AIOfficeDepartments.Common.ps1",
    ".\scripts\departments\AIOfficeDepartmentInbox.Common.ps1",
    ".\scripts\departments\AIOfficeDepartmentExecution.Common.ps1",
    ".\scripts\departments\AIOfficeDepartmentKnowledge.Common.ps1",
    ".\scripts\departments\New-AIOfficeDepartmentWorkItem.ps1",
    ".\scripts\departments\New-AIOfficeDepartmentPlan.ps1",
    ".\scripts\departments\New-AIOfficeDepartmentExecution.ps1",
    ".\scripts\departments\Invoke-AIOfficeDepartmentExecution.ps1",
    ".\scripts\departments\Publish-AIOfficeDepartmentResult.ps1",
    ".\scripts\departments\New-AIOfficeDepartmentKnowledge.ps1",
    ".\scripts\departments\Search-AIOfficeDepartmentKnowledge.ps1",
    ".\scripts\departments\Add-AIOfficeDepartmentLearning.ps1",
    ".\scripts\departments\Convert-AIOfficeDepartmentExecutionToKnowledge.ps1",
    ".\scripts\departments\New-AIOfficeDepartmentReport.ps1",
    ".\scripts\departments\Certify-AIOfficeDepartmentIntelligence.ps1",
    ".\scripts\departments\Test-AIOfficeDepartmentIntelligence.ps1",
    ".\scripts\departments\Publish-AIOfficeDepartmentIntelligenceRelease.ps1"
)

foreach ($Path in $Scripts) {
    $Exists = Test-Path -LiteralPath $Path -PathType Leaf

    Add-DepartmentCheck `
        -Name ("Script exists: " + $Path) `
        -Passed $Exists `
        -Details $(if ($Exists) { "Found." } else { "Missing." })
}

$MessageId = ""
$WorkItemId = ""
$PlanId = ""
$ExecutionId = ""
$ResultMessageId = ""
$KnowledgeId = ""
$LearningId = ""

try {
    $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "chief-of-staff" `
        -To "marketing" `
        -MessageType "handoff" `
        -Priority "high" `
        -Subject "Department Intelligence certification" `
        -ConversationTopic "DEPARTMENT-CERTIFICATION" `
        -Queue "outbox" `
        -PayloadJson '{"objective":"Create a reusable dealership campaign lesson.","deliverables":["Campaign strategy","Reusable lesson"],"required_capabilities":["campaign_strategy"],"risk_level":"low","approval_status":"not_required"}'

    $MessageId = [string]$Message.message_id

    $Inbox = @(
        & ".\scripts\departments\Invoke-AIOfficeDepartmentInbox.ps1" `
            -Department "marketing" `
            -Limit 1
    )

    $WorkItemId = [string]$Inbox[0].work_item_id

    $Plan = & ".\scripts\departments\New-AIOfficeDepartmentPlan.ps1" `
        -Department "marketing" `
        -WorkItemId $WorkItemId `
        -ExecutionMode "internal_reasoning"

    $PlanId = [string]$Plan.department_plan_id

    $Execution = & ".\scripts\departments\New-AIOfficeDepartmentExecution.ps1" `
        -Department "marketing" `
        -DepartmentPlanId $PlanId

    $ExecutionId = [string]$Execution.department_execution_id

    $Execution = & ".\scripts\departments\Invoke-AIOfficeDepartmentExecution.ps1" `
        -Department "marketing" `
        -DepartmentExecutionId $ExecutionId `
        -ResultSummary "Reusable campaign planning lesson completed."

    $Published = & ".\scripts\departments\Publish-AIOfficeDepartmentResult.ps1" `
        -Department "marketing" `
        -DepartmentExecutionId $ExecutionId

    $ResultMessageId = [string]$Published.message_id

    Add-DepartmentCheck `
        -Name "Inbox through execution and result" `
        -Passed (
            [string]$Execution.status -eq "completed" -and
            -not [string]::IsNullOrWhiteSpace($ResultMessageId)
        ) `
        -Details (
            $ExecutionId +
            " | result " +
            $ResultMessageId
        )

    $Knowledge = & `
        ".\scripts\departments\Convert-AIOfficeDepartmentExecutionToKnowledge.ps1" `
        -Department "marketing" `
        -DepartmentExecutionId $ExecutionId `
        -KnowledgeType "lesson" `
        -Confidence 0.90

    $KnowledgeId = [string]$Knowledge.knowledge_id

    Add-DepartmentCheck `
        -Name "Execution to knowledge capture" `
        -Passed (-not [string]::IsNullOrWhiteSpace($KnowledgeId)) `
        -Details $KnowledgeId

    $Search = @(
        & ".\scripts\departments\Search-AIOfficeDepartmentKnowledge.ps1" `
            -Department "marketing" `
            -Query "campaign" `
            -MinimumConfidence 0.50
    )

    Add-DepartmentCheck `
        -Name "Department knowledge search" `
        -Passed ($Search.Count -gt 0) `
        -Details ($Search.Count.ToString() + " result(s)")

    $Learning = & ".\scripts\departments\Add-AIOfficeDepartmentLearning.ps1" `
        -Department "marketing" `
        -EventType "reuse" `
        -SourceId $WorkItemId `
        -Summary "Certification knowledge item reused." `
        -KnowledgeId $KnowledgeId

    $LearningId = [string]$Learning.learning_id

    Add-DepartmentCheck `
        -Name "Department learning record" `
        -Passed (-not [string]::IsNullOrWhiteSpace($LearningId)) `
        -Details $LearningId

    $Report = & ".\scripts\departments\New-AIOfficeDepartmentReport.ps1" `
        -Department "marketing"

    Add-DepartmentCheck `
        -Name "Department report generation" `
        -Passed ($null -ne $Report) `
        -Details ([string]$Report.report_id)
}
catch {
    Add-DepartmentCheck `
        -Name "Offline end-to-end Department Intelligence workflow" `
        -Passed $false `
        -Details $_.Exception.Message
}

foreach ($CurrentMessageId in @($MessageId, $ResultMessageId)) {
    if ([string]::IsNullOrWhiteSpace($CurrentMessageId)) {
        continue
    }

    foreach ($Queue in @(
        "inbox",
        "outbox",
        "processing",
        "processed",
        "failed",
        "dead-letter",
        "archive"
    )) {
        $Path = ".\workspace\messages\$Queue\$CurrentMessageId.json"

        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            Remove-Item -LiteralPath $Path -Force
        }
    }
}

foreach ($Path in @(
    ".\workspace\departments\marketing\work\$WorkItemId.json",
    ".\workspace\departments\marketing\plans\$PlanId.json",
    ".\workspace\departments\marketing\execution\$ExecutionId.json"
)) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

foreach ($Folder in @(
    ".\workspace\departments\marketing\processed-inbox",
    ".\workspace\departments\marketing\failed-inbox"
)) {
    $Path = Join-Path $Folder ($MessageId + ".json")

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

Get-ChildItem `
    -LiteralPath ".\workspace\departments\marketing\classifications" `
    -Filter "DCL-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        $Record = Read-AIOfficeDepartmentJson -Path $_.FullName

        if ($null -ne $Record -and
            [string]$Record.message_id -eq $MessageId) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

Get-ChildItem `
    -LiteralPath ".\workspace\departments\marketing\results" `
    -Filter "DRS-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        $Record = Read-AIOfficeDepartmentJson -Path $_.FullName

        if ($null -ne $Record -and
            [string]$Record.department_execution_id -eq $ExecutionId) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

foreach ($Folder in @(
    "lessons",
    "templates",
    "playbooks",
    "decisions",
    "metrics"
)) {
    $Path = ".\workspace\departments\marketing\knowledge\$Folder\$KnowledgeId.json"

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

if ($LearningId) {
    $Path = ".\workspace\departments\marketing\learning\$LearningId.json"

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

Get-ChildItem `
    -LiteralPath ".\workspace\departments\marketing\learning" `
    -Filter "DLR-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        $Record = Read-AIOfficeDepartmentJson -Path $_.FullName

        if ($null -ne $Record -and
            [string]$Record.knowledge_id -eq $KnowledgeId) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

& ".\scripts\departments\Update-AIOfficeDepartmentIndex.ps1" |
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
    "CERT-DEPT-" +
    (Get-Date).ToString("yyyyMMdd-HHmmss")
)

$Certification = [ordered]@{
    certification_id = $CertificationId
    version = "1.2.0"
    certified_at = (Get-Date).ToString("o")
    status = $Status
    passed_checks = $PassedCount
    failed_checks = $FailedCount
    checks = @($Checks | ForEach-Object { $_ })
}

$Path = Join-Path `
    ".\workspace\departments\certification" `
    ($CertificationId + ".json")

Write-AIOfficeDepartmentJson `
    -Value $Certification `
    -Path $Path

Write-Host (
    "Department Intelligence certification: " +
    $Status +
    " | " +
    $PassedCount.ToString() +
    " passed, " +
    $FailedCount.ToString() +
    " failed"
) -ForegroundColor $(if ($FailedCount -eq 0) { "Green" } else { "Red" })

return [pscustomobject]$Certification
