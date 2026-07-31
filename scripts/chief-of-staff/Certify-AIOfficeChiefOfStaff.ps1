param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffReview.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Checks = New-Object System.Collections.Generic.List[object]

function Add-COSCheck {
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
    ".\config\chief-of-staff\chief-of-staff-identity.json",
    ".\config\chief-of-staff\chief-of-staff-policy.json",
    ".\config\chief-of-staff\inbox-policy.json",
    ".\config\chief-of-staff\delegation-policy.json",
    ".\config\chief-of-staff\review-policy.json",
    ".\config\chief-of-staff\release-manifest.json"
)

foreach ($Path in $JsonFiles) {
    try {
        Get-Content -LiteralPath $Path -Raw |
            ConvertFrom-Json |
            Out-Null

        Add-COSCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $true `
            -Details "Parsed successfully."
    }
    catch {
        Add-COSCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $false `
            -Details $_.Exception.Message
    }
}

$Scripts = @(
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaff.Common.ps1",
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaffInbox.Common.ps1",
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaffDelegation.Common.ps1",
    ".\scripts\chief-of-staff\AIOfficeChiefOfStaffReview.Common.ps1",
    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffPlan.ps1",
    ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffInbox.ps1",
    ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffDispatch.ps1",
    ".\scripts\chief-of-staff\Review-AIOfficeChiefOfStaffResult.ps1",
    ".\scripts\chief-of-staff\Complete-AIOfficeChiefOfStaffPlan.ps1",
    ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffClosedLoop.ps1",
    ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffExecutiveReport.ps1",
    ".\scripts\chief-of-staff\Certify-AIOfficeChiefOfStaff.ps1",
    ".\scripts\chief-of-staff\Test-AIOfficeChiefOfStaff.ps1",
    ".\scripts\chief-of-staff\Publish-AIOfficeChiefOfStaffRelease.ps1"
)

foreach ($Path in $Scripts) {
    $Exists = Test-Path -LiteralPath $Path -PathType Leaf

    Add-COSCheck `
        -Name ("Script exists: " + $Path) `
        -Passed $Exists `
        -Details $(if ($Exists) { "Found." } else { "Missing." })
}

$MessageId = ""
$PlanId = ""
$DelegationId = ""
$WorkPackageId = ""
$DispatchMessageId = ""
$ResultMessageId = ""
$CompletionMessageId = ""

try {
    $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "marketing" `
        -To "chief-of-staff" `
        -MessageType "request" `
        -Priority "high" `
        -Subject "Chief of Staff certification campaign" `
        -ConversationTopic "COS-CERTIFICATION" `
        -Queue "inbox" `
        -PayloadJson '{"objective":"Create and complete a certification campaign plan.","success_criteria":["Plan created","Delegation dispatched","Result reviewed","Plan completed"]}'

    $MessageId = [string]$Message.message_id

    $InboxResults = @(
        & ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffInbox.ps1" `
            -Limit 1 `
            -CreatePlans
    )

    if ($InboxResults.Count -ne 1 -or
        [string]::IsNullOrWhiteSpace([string]$InboxResults[0].plan_id)) {
        throw "Inbox processing did not create a plan."
    }

    $PlanId = [string]$InboxResults[0].plan_id

    Add-COSCheck `
        -Name "Executive inbox to plan" `
        -Passed $true `
        -Details $PlanId

    $Dispatch = & `
        ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffDispatch.ps1" `
        -PlanId $PlanId

    $DelegationId = [string]$Dispatch.delegation.delegation_id
    $WorkPackageId = [string]$Dispatch.work_package.work_package_id
    $DispatchMessageId = [string]$Dispatch.message.message_id

    Add-COSCheck `
        -Name "Plan to delegation dispatch" `
        -Passed (
            -not [string]::IsNullOrWhiteSpace($DelegationId) -and
            -not [string]::IsNullOrWhiteSpace($DispatchMessageId)
        ) `
        -Details (
            $DelegationId +
            " | " +
            $DispatchMessageId
        )

    $ResultPayload = [ordered]@{
        delegation_id = $DelegationId
        plan_id = $PlanId
        status = "completed"
        summary = "Certification work completed."
    }

    $ResultMessage = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From ([string]$Dispatch.delegation.department) `
        -To "chief-of-staff" `
        -MessageType "execution_result" `
        -Priority "normal" `
        -Subject "Certification result" `
        -ConversationId ([string]$Dispatch.message.conversation_id) `
        -CorrelationId ([string]$Dispatch.message.correlation_id) `
        -Queue "inbox" `
        -PayloadJson (
            $ResultPayload |
                ConvertTo-Json -Depth 10 -Compress
        )

    $ResultMessageId = [string]$ResultMessage.message_id

    $ClosedLoop = & `
        ".\scripts\chief-of-staff\Invoke-AIOfficeChiefOfStaffClosedLoop.ps1" `
        -DelegationId $DelegationId `
        -ResultMessageId $ResultMessageId `
        -Outcome "completed" `
        -Summary "Certification result reviewed and approved." `
        -CompletePlan

    if ($null -eq $ClosedLoop.completion -or
        [string]$ClosedLoop.completion.plan.status -ne "completed") {
        throw "Closed-loop completion did not complete the plan."
    }

    $CompletionMessageId = [string](
        $ClosedLoop.completion.completion_message.message_id
    )

    Add-COSCheck `
        -Name "Closed-loop completion" `
        -Passed $true `
        -Details (
            $PlanId +
            " completed | message " +
            $CompletionMessageId
        )

    $Report = & `
        ".\scripts\chief-of-staff\New-AIOfficeChiefOfStaffExecutiveReport.ps1"

    Add-COSCheck `
        -Name "Executive report generation" `
        -Passed ($null -ne $Report) `
        -Details ([string]$Report.report_id)
}
catch {
    Add-COSCheck `
        -Name "Offline end-to-end Chief of Staff workflow" `
        -Passed $false `
        -Details $_.Exception.Message
}

# Cleanup certification-generated runtime records.
foreach ($CurrentMessageId in @(
    $MessageId,
    $DispatchMessageId,
    $ResultMessageId,
    $CompletionMessageId
)) {
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

    foreach ($Folder in @(
        ".\workspace\chief-of-staff\processed-inbox",
        ".\workspace\chief-of-staff\failed-inbox"
    )) {
        $Path = Join-Path $Folder ($CurrentMessageId + ".json")

        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            Remove-Item -LiteralPath $Path -Force
        }
    }
}

foreach ($Path in @(
    ".\workspace\chief-of-staff\plans\$PlanId.json",
    ".\workspace\chief-of-staff\completed\$PlanId.json",
    ".\workspace\chief-of-staff\delegations\$DelegationId.json",
    ".\workspace\chief-of-staff\work-packages\$WorkPackageId.json"
)) {
    if (-not [string]::IsNullOrWhiteSpace($Path) -and
        (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Remove-Item -LiteralPath $Path -Force
    }
}

foreach ($Folder in @(
    ".\workspace\chief-of-staff\classifications",
    ".\workspace\chief-of-staff\routing",
    ".\workspace\chief-of-staff\reviews",
    ".\workspace\chief-of-staff\approvals"
)) {
    Get-ChildItem `
        -LiteralPath $Folder `
        -Filter "*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        ForEach-Object {
            $Record = Read-AIOfficeChiefOfStaffJson -Path $_.FullName

            if ($null -ne $Record -and
                (
                    [string]$Record.plan_id -eq $PlanId -or
                    [string]$Record.message_id -eq $MessageId -or
                    [string]$Record.delegation_id -eq $DelegationId
                )) {
                Remove-Item -LiteralPath $_.FullName -Force
            }
        }
}

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
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
    "CERT-COS-" +
    (Get-Date).ToString("yyyyMMdd-HHmmss")
)

$Certification = [ordered]@{
    certification_id = $CertificationId
    version = "1.1.4"
    certified_at = (Get-Date).ToString("o")
    status = $Status
    passed_checks = $PassedCount
    failed_checks = $FailedCount
    checks = @($Checks | ForEach-Object { $_ })
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\certification" `
    ($CertificationId + ".json")

Write-AIOfficeChiefOfStaffJson `
    -Value $Certification `
    -Path $Path

Write-Host (
    "Chief of Staff certification: " +
    $Status +
    " | " +
    $PassedCount.ToString() +
    " passed, " +
    $FailedCount.ToString() +
    " failed"
) -ForegroundColor $(if ($FailedCount -eq 0) { "Green" } else { "Red" })

return [pscustomobject]$Certification
