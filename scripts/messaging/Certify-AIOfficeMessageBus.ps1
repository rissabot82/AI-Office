param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMessaging.Common.ps1")

$Root = Get-AIOfficeMessagingRoot
Set-Location $Root

$Checks = New-Object System.Collections.Generic.List[object]

function Add-CertificationCheck {
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

$RequiredJson = @(
    ".\config\messaging\messaging-policy.json",
    ".\config\messaging\message-schema.json",
    ".\config\messaging\routing-policy.json",
    ".\config\messaging\queue-policy.json",
    ".\config\messaging\processing-policy.json",
    ".\config\messaging\release-manifest.json",
    ".\config\messaging\certification-schema.json"
)

foreach ($Path in $RequiredJson) {
    try {
        Get-Content -LiteralPath $Path -Raw |
            ConvertFrom-Json |
            Out-Null

        Add-CertificationCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $true `
            -Details "Parsed successfully."
    }
    catch {
        Add-CertificationCheck `
            -Name ("Valid JSON: " + $Path) `
            -Passed $false `
            -Details $_.Exception.Message
    }
}

$RequiredScripts = @(
    ".\scripts\messaging\AIOfficeMessaging.Common.ps1",
    ".\scripts\messaging\New-AIOfficeMessage.ps1",
    ".\scripts\messaging\Move-AIOfficeMessage.ps1",
    ".\scripts\messaging\Get-AIOfficeMessage.ps1",
    ".\scripts\messaging\Receive-AIOfficeMessage.ps1",
    ".\scripts\messaging\Acknowledge-AIOfficeMessage.ps1",
    ".\scripts\messaging\Route-AIOfficeMessage.ps1",
    ".\scripts\messaging\Search-AIOfficeMessages.ps1",
    ".\scripts\messaging\Complete-AIOfficeMessage.ps1",
    ".\scripts\messaging\Fail-AIOfficeMessage.ps1",
    ".\scripts\messaging\Retry-AIOfficeMessage.ps1",
    ".\scripts\messaging\Move-AIOfficeMessageToDeadLetter.ps1",
    ".\scripts\messaging\Recover-AIOfficeDeadLetterMessage.ps1",
    ".\scripts\messaging\Archive-AIOfficeMessage.ps1",
    ".\scripts\messaging\Invoke-AIOfficeMessageMaintenance.ps1",
    ".\scripts\messaging\Invoke-AIOfficeMessageProcessor.ps1",
    ".\scripts\messaging\Retry-AIOfficeFailedMessages.ps1",
    ".\scripts\messaging\New-AIOfficeSampleConversation.ps1",
    ".\scripts\messaging\Certify-AIOfficeMessageBus.ps1",
    ".\scripts\messaging\Test-AIOfficeMessageBus.ps1"
)

foreach ($Path in $RequiredScripts) {
    Add-CertificationCheck `
        -Name ("Script exists: " + $Path) `
        -Passed (Test-Path -LiteralPath $Path -PathType Leaf) `
        -Details $(if (Test-Path -LiteralPath $Path -PathType Leaf) {
            "Found."
        }
        else {
            "Missing."
        })
}

$IdentityPath = ".\config\identity\office.json"

Add-CertificationCheck `
    -Name "Identity integration" `
    -Passed (Test-Path -LiteralPath $IdentityPath -PathType Leaf) `
    -Details "Identity System v1.1.1 is present."

$QueueFolders = @(
    "inbox",
    "outbox",
    "processing",
    "processed",
    "failed",
    "dead-letter",
    "archive"
)

foreach ($Queue in $QueueFolders) {
    $QueuePath = Get-AIOfficeMessageQueuePath -Queue $Queue

    Add-CertificationCheck `
        -Name ("Queue exists: " + $Queue) `
        -Passed (Test-Path -LiteralPath $QueuePath -PathType Container) `
        -Details $QueuePath
}

$PassedCount = @($Checks | Where-Object { $_.passed -eq $true }).Count
$FailedCount = @($Checks | Where-Object { $_.passed -eq $false }).Count

$Status = if ($FailedCount -eq 0) {
    "certified"
}
else {
    "failed"
}

$Certification = [ordered]@{
    certification_id = (
        "CERT-MSG-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss")
    )
    version = "1.1.2"
    certified_at = (Get-Date).ToString("o")
    status = $Status
    passed_checks = $PassedCount
    failed_checks = $FailedCount
    checks = @($Checks | ForEach-Object { $_ })
}

$Path = Join-Path `
    ".\workspace\messages\certification" `
    ([string]$Certification.certification_id + ".json")

Write-AIOfficeMessagingJson -Value $Certification -Path $Path

Write-Host (
    "Message Bus certification: " +
    $Status +
    " | " +
    $PassedCount.ToString() +
    " passed, " +
    $FailedCount.ToString() +
    " failed"
) -ForegroundColor $(if ($FailedCount -eq 0) { "Green" } else { "Red" })

return [pscustomobject]$Certification
