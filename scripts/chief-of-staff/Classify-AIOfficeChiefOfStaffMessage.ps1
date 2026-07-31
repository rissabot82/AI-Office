param(
    [Parameter(Mandatory=$true)][string]$MessageId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffInbox.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Message = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId $MessageId

$Rule = Get-AIOfficeChiefOfStaffClassificationRule `
    -MessageType ([string]$Message.message_type)

if ($null -eq $Rule) {
    $Rule = [pscustomobject]@{
        classification = "general"
        default_priority = "normal"
        default_risk = "medium"
    }
}

$Priority = [string]$Rule.default_priority
$Risk = [string]$Rule.default_risk

if (-not [string]::IsNullOrWhiteSpace([string]$Message.priority)) {
    $Priority = [string]$Message.priority
}

$ApprovalRequired = Test-AIOfficeChiefOfStaffApprovalRequired `
    -RiskLevel $Risk

$ClassificationId = New-AIOfficeChiefOfStaffClassificationId

$Record = [ordered]@{
    classification_id = $ClassificationId
    message_id = $MessageId
    classification = [string]$Rule.classification
    priority = $Priority
    risk_level = $Risk
    approval_required = $ApprovalRequired
    created_at = (Get-Date).ToString("o")
}

$Path = Join-Path `
    ".\workspace\chief-of-staff\classifications" `
    ($ClassificationId + ".json")

Write-AIOfficeChiefOfStaffJson `
    -Value $Record `
    -Path $Path

Write-Host (
    "Message classified: " +
    $MessageId +
    " -> " +
    [string]$Record.classification
) -ForegroundColor Green

return [pscustomobject]$Record
