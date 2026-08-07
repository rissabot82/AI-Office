param(
    [Parameter(Mandatory=$true)][string]$Department,
    [string]$RequiredCapability = ""
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\multi-agent\AIOfficeMultiAgent.Common.ps1"

$Agents = @(
    Get-ChildItem `
        -LiteralPath "E:\AI\AI-Office\workspace\multi-agent\agents" `
        -Filter "AGT-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
    ForEach-Object {
        Read-AIOfficeMultiAgentJson -Path $_.FullName
    } |
    Where-Object {
        $null -ne $_ -and
        [string]$_.department -eq $Department
    }
)

if ($RequiredCapability) {
    $Agents = @(
        $Agents |
        Where-Object {
            @($_.capabilities) -contains $RequiredCapability
        }
    )
}

if ($Agents.Count -lt 1) {
    throw "No matching agent found for department '$Department'."
}

$Assignments = @(
    Get-ChildItem `
        -LiteralPath "E:\AI\AI-Office\workspace\multi-agent\assignments" `
        -Filter "ASN-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
    ForEach-Object {
        Read-AIOfficeMultiAgentJson -Path $_.FullName
    } |
    Where-Object { $null -ne $_ }
)

$Ranked = @(
    foreach ($Agent in $Agents) {
        $OpenCount = @(
            $Assignments |
            Where-Object {
                [string]$_.agent_id -eq [string]$Agent.agent_id -and
                [string]$_.status -ne "completed"
            }
        ).Count

        [pscustomobject]@{
            agent = $Agent
            open_assignments = $OpenCount
            availability_rank = if ([string]$Agent.status -eq "available") { 0 } else { 1 }
        }
    }
)

$Selected = $Ranked |
    Sort-Object availability_rank, open_assignments |
    Select-Object -First 1

Write-Host "Agent selected: $($Selected.agent.agent_id) | $($Selected.agent.name) | open=$($Selected.open_assignments)" -ForegroundColor Green
return $Selected.agent
