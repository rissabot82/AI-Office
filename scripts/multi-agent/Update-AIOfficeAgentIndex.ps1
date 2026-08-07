param()

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
    Where-Object { $null -ne $_ }
)

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

$Collaborations = @(
    Get-ChildItem `
        -LiteralPath "E:\AI\AI-Office\workspace\multi-agent\collaborations" `
        -Filter "COL-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
    ForEach-Object {
        Read-AIOfficeMultiAgentJson -Path $_.FullName
    } |
    Where-Object { $null -ne $_ }
)

$DepartmentCounts = [ordered]@{}
$RoleCounts = [ordered]@{}

foreach ($Agent in $Agents) {
    $Department = [string]$Agent.department
    $Role = [string]$Agent.role

    if (-not $DepartmentCounts.Contains($Department)) {
        $DepartmentCounts[$Department] = 0
    }

    if (-not $RoleCounts.Contains($Role)) {
        $RoleCounts[$Role] = 0
    }

    $DepartmentCounts[$Department]++
    $RoleCounts[$Role]++
}

$Index = [ordered]@{
    version = "1.6.0"
    updated_at = (Get-Date).ToString("o")
    status = "ready"
    agent_count = $Agents.Count
    available_count = @($Agents | Where-Object { [string]$_.status -eq "available" }).Count
    busy_count = @($Agents | Where-Object { [string]$_.status -eq "busy" }).Count
    assignment_count = $Assignments.Count
    open_assignment_count = @($Assignments | Where-Object { [string]$_.status -ne "completed" }).Count
    collaboration_count = $Collaborations.Count
    active_collaboration_count = @($Collaborations | Where-Object { [string]$_.status -eq "active" }).Count
    department_counts = $DepartmentCounts
    role_counts = $RoleCounts
}

Write-AIOfficeMultiAgentJson `
    -Value $Index `
    -Path "E:\AI\AI-Office\workspace\multi-agent\indexes\agent-index.json"

Write-Host "Agent index updated: $($Agents.Count) agents | $($Assignments.Count) assignments | $($Collaborations.Count) collaborations" -ForegroundColor Green
return [pscustomobject]$Index
