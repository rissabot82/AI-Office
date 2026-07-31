param(
    [Parameter(Mandatory=$true)][string]$BridgeRequestId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridge.Common.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

$Path = Join-Path `
    ".\workspace\bridge\requests" `
    ($BridgeRequestId + ".json")

$Request = Read-AIOfficeBridgeJson -Path $Path

if ($null -eq $Request) {
    throw "Bridge request not found: $BridgeRequestId"
}

$ApprovalValid = Test-AIOfficeBridgeApproval `
    -RiskLevel ([string]$Request.risk_level) `
    -ApprovalStatus ([string]$Request.approval_status)

$Validation = [ordered]@{
    bridge_request_id = $BridgeRequestId
    request_exists = $true
    target_engine_valid = ([string]$Request.target_engine -eq "OpenClaw")
    status_valid = ([string]$Request.status -eq "queued")
    approval_valid = $ApprovalValid
    message_id_present = (-not [string]::IsNullOrWhiteSpace([string]$Request.message_id))
    payload_present = ($null -ne $Request.payload)
}

$Validation.valid = (
    $Validation.request_exists -and
    $Validation.target_engine_valid -and
    $Validation.status_valid -and
    $Validation.approval_valid -and
    $Validation.message_id_present -and
    $Validation.payload_present
)

return [pscustomobject]$Validation
