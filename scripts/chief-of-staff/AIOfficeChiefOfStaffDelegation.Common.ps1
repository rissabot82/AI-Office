. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaff.Common.ps1")

function Get-AIOfficeChiefOfStaffDelegationPolicy {
    $Root = Get-AIOfficeChiefOfStaffRoot

    return Read-AIOfficeChiefOfStaffJson `
        -Path (Join-Path $Root "config\chief-of-staff\delegation-policy.json")
}

function New-AIOfficeChiefOfStaffDelegationId {
    return (
        "DLG-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeChiefOfStaffWorkPackageId {
    return (
        "WPK-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeChiefOfStaffPlan {
    param([Parameter(Mandatory=$true)][string]$PlanId)

    $Root = Get-AIOfficeChiefOfStaffRoot
    $Path = Join-Path `
        $Root `
        ("workspace\chief-of-staff\plans\" + $PlanId + ".json")

    $Plan = Read-AIOfficeChiefOfStaffJson -Path $Path

    if ($null -eq $Plan) {
        throw "Chief of Staff plan not found: $PlanId"
    }

    return $Plan
}

function Get-AIOfficeChiefOfStaffDepartment {
    param(
        [Parameter(Mandatory=$true)][string]$Text
    )

    $Policy = Get-AIOfficeChiefOfStaffDelegationPolicy

    if ($null -eq $Policy) {
        throw "Chief of Staff delegation policy could not be loaded."
    }

    $LowerText = $Text.ToLowerInvariant()
    $Scores = @{}

    foreach ($Property in $Policy.routing.department_keywords.PSObject.Properties) {
        $Score = 0

        foreach ($Keyword in @($Property.Value)) {
            if ($LowerText.Contains(([string]$Keyword).ToLowerInvariant())) {
                $Score++
            }
        }

        $Scores[[string]$Property.Name] = $Score
    }

    $Winner = $Scores.GetEnumerator() |
        Sort-Object Value -Descending |
        Select-Object -First 1

    if ($null -eq $Winner -or [int]$Winner.Value -lt 1) {
        return [string]$Policy.routing.default_department
    }

    return [string]$Winner.Key
}

function Test-AIOfficeChiefOfStaffDispatchAllowed {
    param(
        [Parameter(Mandatory=$true)][string]$RiskLevel,
        [Parameter(Mandatory=$true)][string]$ApprovalStatus
    )

    $Policy = Get-AIOfficeChiefOfStaffDelegationPolicy

    if (@($Policy.delegation.require_approval_before_dispatch_for) -contains
        $RiskLevel) {
        return $ApprovalStatus -eq "approved"
    }

    return $true
}
