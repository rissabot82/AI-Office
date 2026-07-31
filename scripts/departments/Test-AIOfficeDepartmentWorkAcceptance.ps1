param(
    [Parameter(Mandatory=$true)][string]$Department,
    [Parameter(Mandatory=$true)][string]$MessageId
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentInbox.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Profile = Get-AIOfficeDepartmentProfile -Department $Department
$Message = & ".\scripts\messaging\Get-AIOfficeMessage.ps1" `
    -MessageId $MessageId

$Requested = @(
    Get-AIOfficeRequestedCapabilities -Payload $Message.payload
)

$Matched = New-Object System.Collections.Generic.List[string]
$Missing = New-Object System.Collections.Generic.List[string]

foreach ($Capability in $Requested) {
    if (@($Profile.capabilities) -contains [string]$Capability) {
        $Matched.Add([string]$Capability)
    }
    else {
        $Missing.Add([string]$Capability)
    }
}

$Accepted = ($Missing.Count -eq 0)

$Classification = [ordered]@{
    classification_id = New-AIOfficeDepartmentClassificationId
    department = $Department
    message_id = $MessageId
    accepted = $Accepted
    matched_capabilities = @($Matched)
    missing_capabilities = @($Missing)
    created_at = (Get-Date).ToString("o")
}

$Path = Join-Path `
    ".\workspace\departments\$Department\classifications" `
    ([string]$Classification.classification_id + ".json")

Write-AIOfficeDepartmentJson `
    -Value $Classification `
    -Path $Path

Write-Host (
    "Department intake classified: " +
    $MessageId +
    " | accepted=" +
    [string]$Accepted
) -ForegroundColor Green

return [pscustomobject]$Classification
