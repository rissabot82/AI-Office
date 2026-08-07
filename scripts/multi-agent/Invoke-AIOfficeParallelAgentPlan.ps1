param(
    [Parameter(Mandatory=$true)][string]$AssignmentsJson
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\multi-agent\AIOfficeMultiAgent.Common.ps1"

try {
    $Definitions = @((ConvertFrom-Json -InputObject $AssignmentsJson) | ForEach-Object { $_ })
}
catch {
    throw "AssignmentsJson is invalid JSON."
}

$Policy = Get-Content `
    -LiteralPath "E:\AI\AI-Office\config\multi-agent\collaboration-policy.json" `
    -Raw |
    ConvertFrom-Json

$Maximum = [int]$Policy.parallel_execution.maximum_parallel_agents

if ($Definitions.Count -gt $Maximum) {
    throw "Parallel plan exceeds maximum of $Maximum agents."
}

$Created = New-Object System.Collections.Generic.List[object]

foreach ($Definition in $Definitions) {
    $Agent = & "E:\AI\AI-Office\scripts\multi-agent\Select-AIOfficeAgentForWork.ps1" `
        -Department ([string]$Definition.department) `
        -RequiredCapability ([string]$Definition.required_capability)

    $Assignment = & "E:\AI\AI-Office\scripts\multi-agent\New-AIOfficeAgentAssignment.ps1" `
        -AgentId ([string]$Agent.agent_id) `
        -WorkType ([string]$Definition.work_type) `
        -WorkRef ([string]$Definition.work_ref) `
        -Priority ([string]$Definition.priority) `
        -Instructions ([string]$Definition.instructions)

    $Created.Add($Assignment)
}

Write-Host "Parallel agent plan created: $($Created.Count) assignment(s)." -ForegroundColor Green
return @($Created | ForEach-Object { $_ })
