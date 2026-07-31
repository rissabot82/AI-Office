. (Join-Path $PSScriptRoot "AIOfficeDepartments.Common.ps1")

function Get-AIOfficeDepartmentExecutionPolicy {
    $Root = Get-AIOfficeDepartmentRoot

    return Read-AIOfficeDepartmentJson `
        -Path (Join-Path $Root "config\departments\department-execution-policy.json")
}

function New-AIOfficeDepartmentPlanId {
    return (
        "DPL-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeDepartmentExecutionId {
    return (
        "DEX-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeDepartmentWorkItem {
    param(
        [Parameter(Mandatory=$true)][string]$Department,
        [Parameter(Mandatory=$true)][string]$WorkItemId
    )

    $Root = Get-AIOfficeDepartmentRoot
    $Path = Join-Path `
        $Root `
        ("workspace\departments\" + $Department + "\work\" + $WorkItemId + ".json")

    $WorkItem = Read-AIOfficeDepartmentJson -Path $Path

    if ($null -eq $WorkItem) {
        throw "Department work item not found: $WorkItemId"
    }

    return $WorkItem
}

function Get-AIOfficeDepartmentPlan {
    param(
        [Parameter(Mandatory=$true)][string]$Department,
        [Parameter(Mandatory=$true)][string]$DepartmentPlanId
    )

    $Root = Get-AIOfficeDepartmentRoot
    $Path = Join-Path `
        $Root `
        ("workspace\departments\" + $Department + "\plans\" + $DepartmentPlanId + ".json")

    $Plan = Read-AIOfficeDepartmentJson -Path $Path

    if ($null -eq $Plan) {
        throw "Department plan not found: $DepartmentPlanId"
    }

    return $Plan
}
