param(
    [Parameter(Mandatory=$true)][string]$Department,
    [string]$Status = "",
    [string]$Priority = "",
    [string]$RiskLevel = "",
    [int]$Limit = 100
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartments.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Results = New-Object System.Collections.Generic.List[object]

foreach ($File in @(
    Get-ChildItem `
        -LiteralPath ".\workspace\departments\$Department\work" `
        -Filter "DWI-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    $WorkItem = Read-AIOfficeDepartmentJson -Path $File.FullName

    if ($null -eq $WorkItem) {
        continue
    }

    if ($Status -and [string]$WorkItem.status -ne $Status) {
        continue
    }

    if ($Priority -and [string]$WorkItem.priority -ne $Priority) {
        continue
    }

    if ($RiskLevel -and [string]$WorkItem.risk_level -ne $RiskLevel) {
        continue
    }

    $Results.Add([pscustomobject]@{
        work_item_id = [string]$WorkItem.work_item_id
        department = [string]$WorkItem.department
        title = [string]$WorkItem.title
        priority = [string]$WorkItem.priority
        risk_level = [string]$WorkItem.risk_level
        approval_status = [string]$WorkItem.approval_status
        status = [string]$WorkItem.status
        source_message_id = [string]$WorkItem.source_message_id
        created_at = [string]$WorkItem.created_at
    })
}

return @(
    $Results |
        Sort-Object created_at -Descending |
        Select-Object -First $Limit
)
