param(
    [Parameter(Mandatory=$true)][string]$PlanId,
    [string]$Summary = "",
    [string]$CompletedBy = "chief-of-staff"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeChiefOfStaffReview.Common.ps1")

$Root = Get-AIOfficeChiefOfStaffRoot
Set-Location $Root

$Plan = Get-AIOfficeChiefOfStaffPlan -PlanId $PlanId

$Delegations = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\chief-of-staff\delegations" `
        -Filter "DLG-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
        ForEach-Object {
            $Delegation = Read-AIOfficeChiefOfStaffJson `
                -Path $_.FullName

            if ($null -ne $Delegation -and
                [string]$Delegation.plan_id -eq $PlanId) {
                $Delegation
            }
        }
)

$Incomplete = @(
    $Delegations |
        Where-Object {
            @("completed","partially_completed") -notcontains
            [string]$_.status
        }
)

if ($Incomplete.Count -gt 0) {
    throw (
        "Plan cannot be completed. " +
        $Incomplete.Count.ToString() +
        " delegation(s) remain incomplete."
    )
}

$Now = (Get-Date).ToString("o")
$Plan.status = "completed"
$Plan.updated_at = $Now

foreach ($Property in @(
    @{ Name = "completed_at"; Value = $Now },
    @{ Name = "completed_by"; Value = $CompletedBy },
    @{ Name = "completion_summary"; Value = $Summary }
)) {
    if ($null -ne $Plan.PSObject.Properties[$Property.Name]) {
        $Plan.($Property.Name) = $Property.Value
    }
    else {
        $Plan | Add-Member `
            -MemberType NoteProperty `
            -Name $Property.Name `
            -Value $Property.Value
    }
}

$History = New-Object System.Collections.Generic.List[object]

foreach ($Entry in @($Plan.history)) {
    $History.Add($Entry)
}

$History.Add([ordered]@{
    timestamp = $Now
    action = "completed"
    actor = $CompletedBy
    details = if ([string]::IsNullOrWhiteSpace($Summary)) {
        "Chief of Staff plan completed."
    }
    else {
        $Summary
    }
})

$Plan.history = @($History | ForEach-Object { $_ })

$PlanPath = ".\workspace\chief-of-staff\plans\$PlanId.json"

Write-AIOfficeChiefOfStaffJson `
    -Value $Plan `
    -Path $PlanPath

$CompletedPath = Join-Path `
    ".\workspace\chief-of-staff\completed" `
    ($PlanId + ".json")

Write-AIOfficeChiefOfStaffJson `
    -Value $Plan `
    -Path $CompletedPath

$Payload = [ordered]@{
    plan_id = $PlanId
    status = "completed"
    title = [string]$Plan.title
    objective = [string]$Plan.objective
    summary = $Summary
    completed_at = $Now
    delegation_count = $Delegations.Count
}

$Arguments = @{
    From = "chief-of-staff"
    To = "chief-of-staff"
    MessageType = "status"
    Subject = ("Plan completed: " + [string]$Plan.title)
    Priority = "normal"
    WorkflowId = [string]$Plan.workflow_id
    Queue = "inbox"
    PayloadJson = ($Payload | ConvertTo-Json -Depth 20 -Compress)
}

if (-not [string]::IsNullOrWhiteSpace([string]$Plan.correlation_id)) {
    $Arguments.CorrelationId = [string]$Plan.correlation_id
}

if (-not [string]::IsNullOrWhiteSpace([string]$Plan.conversation_id)) {
    $Arguments.ConversationId = [string]$Plan.conversation_id
}

$Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" @Arguments

& ".\scripts\chief-of-staff\Update-AIOfficeChiefOfStaffIndex.ps1" |
    Out-Null

Write-Host (
    "Chief of Staff plan completed: " +
    $PlanId
) -ForegroundColor Green

return [pscustomobject]@{
    plan = $Plan
    completion_message = $Message
}

