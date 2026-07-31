. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffDelegation.Common.ps1")
. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaff.Common.ps1")

function Get-AIOfficeChiefOfStaffReviewPolicy {
    $Root = Get-AIOfficeChiefOfStaffRoot

    return Read-AIOfficeChiefOfStaffJson `
        -Path (Join-Path $Root "config\chief-of-staff\review-policy.json")
}

function New-AIOfficeChiefOfStaffReviewId {
    return (
        "REV-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeChiefOfStaffApprovalId {
    return (
        "APR-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeChiefOfStaffDelegation {
    param([Parameter(Mandatory=$true)][string]$DelegationId)

    $Root = Get-AIOfficeChiefOfStaffRoot
    $Path = Join-Path `
        $Root `
        ("workspace\chief-of-staff\delegations\" + $DelegationId + ".json")

    $Delegation = Read-AIOfficeChiefOfStaffJson -Path $Path

    if ($null -eq $Delegation) {
        throw "Delegation not found: $DelegationId"
    }

    return $Delegation
}

