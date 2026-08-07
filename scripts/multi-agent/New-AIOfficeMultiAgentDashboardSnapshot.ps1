param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

. "E:\AI\AI-Office\scripts\multi-agent\AIOfficeMultiAgent.Common.ps1"

$Index = & "E:\AI\AI-Office\scripts\multi-agent\Update-AIOfficeAgentIndex.ps1"

function Read-JsonCollection {
    param(
        [Parameter(Mandatory=$true)][string]$Directory,
        [Parameter(Mandatory=$true)][string]$Filter,
        [int]$Limit = 12
    )

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        return @()
    }

    return @(
        Get-ChildItem `
            -LiteralPath $Directory `
            -Filter $Filter `
            -File `
            -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First $Limit |
        ForEach-Object {
            try {
                Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
            }
            catch {
            }
        } |
        Where-Object { $null -ne $_ }
    )
}

$Agents = Read-JsonCollection `
    -Directory "E:\AI\AI-Office\workspace\multi-agent\agents" `
    -Filter "AGT-*.json" `
    -Limit 20

$Assignments = Read-JsonCollection `
    -Directory "E:\AI\AI-Office\workspace\multi-agent\assignments" `
    -Filter "ASN-*.json" `
    -Limit 20

$Collaborations = Read-JsonCollection `
    -Directory "E:\AI\AI-Office\workspace\multi-agent\collaborations" `
    -Filter "COL-*.json" `
    -Limit 12

$Handoffs = Read-JsonCollection `
    -Directory "E:\AI\AI-Office\workspace\multi-agent\handoffs" `
    -Filter "HOF-*.json" `
    -Limit 12

$Reviews = Read-JsonCollection `
    -Directory "E:\AI\AI-Office\workspace\multi-agent\reviews" `
    -Filter "REVAGT-*.json" `
    -Limit 12

$Consensus = Read-JsonCollection `
    -Directory "E:\AI\AI-Office\workspace\multi-agent\consensus" `
    -Filter "CNS-*.json" `
    -Limit 12

$Conflicts = Read-JsonCollection `
    -Directory "E:\AI\AI-Office\workspace\multi-agent\conflicts" `
    -Filter "CNF-*.json" `
    -Limit 12

$OpenConflicts = @(
    $Conflicts |
    Where-Object {
        [string]$_.status -eq "open" -or
        [string]$_.status -eq "escalated"
    }
).Count

$RecentEvents = New-Object System.Collections.Generic.List[object]

foreach ($Item in $Handoffs) {
    $RecentEvents.Add([pscustomobject]@{
        event_type = "handoff"
        title = ([string]$Item.from_agent_name + " → " + [string]$Item.to_agent_name)
        status = [string]$Item.status
        detail = [string]$Item.reason
        occurred_at = [string]$Item.updated_at
    })
}

foreach ($Item in $Reviews) {
    $RecentEvents.Add([pscustomobject]@{
        event_type = "review"
        title = [string]$Item.reviewer_agent_name
        status = [string]$Item.verdict
        detail = (
            [string]$Item.subject_type +
            " " +
            [string]$Item.subject_ref +
            " · score " +
            [string]$Item.score
        )
        occurred_at = [string]$Item.created_at
    })
}

foreach ($Item in $Consensus) {
    $RecentEvents.Add([pscustomobject]@{
        event_type = "consensus"
        title = [string]$Item.topic
        status = [string]$Item.status
        detail = ("approval ratio " + [string]$Item.approval_ratio)
        occurred_at = [string]$Item.updated_at
    })
}

foreach ($Item in $Conflicts) {
    $RecentEvents.Add([pscustomobject]@{
        event_type = "conflict"
        title = [string]$Item.title
        status = [string]$Item.status
        detail = [string]$Item.resolution
        occurred_at = [string]$Item.updated_at
    })
}

$RecentEvents = @(
    $RecentEvents |
    Sort-Object occurred_at -Descending |
    Select-Object -First 12
)

$Snapshot = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    status = [string]$Index.status
    agent_count = [int]$Index.agent_count
    available_count = [int]$Index.available_count
    busy_count = [int]$Index.busy_count
    assignment_count = [int]$Index.assignment_count
    open_assignment_count = [int]$Index.open_assignment_count
    collaboration_count = [int]$Index.collaboration_count
    active_collaboration_count = [int]$Index.active_collaboration_count
    handoff_count = @($Handoffs).Count
    review_count = @($Reviews).Count
    consensus_count = @($Consensus).Count
    conflict_count = @($Conflicts).Count
    open_conflict_count = $OpenConflicts
    department_counts = $Index.department_counts
    role_counts = $Index.role_counts
    agents = @(
        $Agents |
        ForEach-Object {
            [ordered]@{
                agent_id = [string]$_.agent_id
                name = [string]$_.name
                role = [string]$_.role
                department = [string]$_.department
                status = [string]$_.status
                capabilities = @($_.capabilities)
                updated_at = [string]$_.updated_at
            }
        }
    )
    assignments = @(
        $Assignments |
        ForEach-Object {
            [ordered]@{
                assignment_id = [string]$_.assignment_id
                agent_id = [string]$_.agent_id
                agent_name = [string]$_.agent_name
                department = [string]$_.department
                work_type = [string]$_.work_type
                status = [string]$_.status
                priority = [string]$_.priority
                updated_at = [string]$_.updated_at
            }
        }
    )
    collaborations = @(
        $Collaborations |
        ForEach-Object {
            [ordered]@{
                collaboration_id = [string]$_.collaboration_id
                title = [string]$_.title
                status = [string]$_.status
                objective = [string]$_.objective
                participant_count = @($_.participants).Count
                updated_at = [string]$_.updated_at
            }
        }
    )
    recent_events = @($RecentEvents | ForEach-Object { $_ })
}

$OutputPath = "E:\AI\AI-Office\dashboard\public\multi-agent-status.json"

$Snapshot |
    ConvertTo-Json -Depth 80 |
    Set-Content -LiteralPath $OutputPath -Encoding UTF8

Write-Host "Multi-Agent dashboard snapshot updated." -ForegroundColor Green
return [pscustomobject]$Snapshot
