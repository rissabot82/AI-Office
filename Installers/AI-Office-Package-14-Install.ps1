# ============================================================
# AI Office Package 14
# Agent Collaboration Layer
# Repository: E:\AI\AI-Office
# ============================================================

$ErrorActionPreference = "Stop"
$repository = "E:\AI\AI-Office"

if (-not (Test-Path -LiteralPath $repository -PathType Container)) {
    throw "AI Office repository not found at $repository"
}

Set-Location $repository

function New-SafeDirectory {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

function New-SafeFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][AllowEmptyString()][string]$Content
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $parent = Split-Path -Parent $Path

        if (-not [string]::IsNullOrWhiteSpace($parent) -and
            -not (Test-Path -LiteralPath $parent -PathType Container)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    else {
        Write-Host "[EXISTS ] $Path" -ForegroundColor DarkGray
    }
}

$folders = @(
    ".\config\collaboration",
    ".\workspace\collaboration",
    ".\workspace\collaboration\agents",
    ".\workspace\collaboration\messages",
    ".\workspace\collaboration\queues",
    ".\workspace\collaboration\delegations",
    ".\workspace\collaboration\conflicts",
    ".\workspace\collaboration\shared-context",
    ".\workspace\collaboration\archive",
    ".\scripts\collaboration",
    ".\docs",
    ".\Installers"
)

foreach ($folder in $folders) {
    New-SafeDirectory -Path $folder
}

$policy = @'
{
  "version": "1.0.0",
  "layer_name": "AI Office Agent Collaboration Layer",
  "default_timezone": "America/Chicago",
  "max_delegation_depth": 6,
  "message_retention_days": 90,
  "conflict_escalation_minutes": 60,
  "default_queue_capacity": 500,
  "allowed_agent_statuses": [
    "available",
    "busy",
    "offline",
    "paused"
  ],
  "allowed_message_types": [
    "information",
    "request",
    "response",
    "handoff",
    "escalation",
    "decision",
    "status"
  ],
  "allowed_delegation_statuses": [
    "assigned",
    "accepted",
    "in_progress",
    "completed",
    "rejected",
    "escalated",
    "cancelled"
  ],
  "conflict_resolution_order": [
    "owner",
    "department_lead",
    "chief_of_staff"
  ]
}
'@

New-SafeFile ".\config\collaboration\collaboration-policy.json" $policy

$agentSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/agent-profile-schema.json",
  "title": "AI Office Agent Profile",
  "type": "object",
  "required": [
    "agent_id",
    "name",
    "department",
    "role",
    "status",
    "capabilities",
    "created_at",
    "updated_at"
  ],
  "properties": {
    "agent_id": {
      "type": "string",
      "pattern": "^AGT-[A-Z0-9-]+$"
    },
    "name": {
      "type": "string",
      "minLength": 1
    },
    "department": {
      "type": "string",
      "minLength": 1
    },
    "role": {
      "type": "string",
      "minLength": 1
    },
    "status": {
      "type": "string"
    },
    "capabilities": {
      "type": "array"
    },
    "manager_agent_id": {
      "type": "string"
    },
    "created_at": {
      "type": "string"
    },
    "updated_at": {
      "type": "string"
    }
  }
}
'@

New-SafeFile ".\config\collaboration\agent-profile-schema.json" $agentSchema

$messageSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/agent-message-schema.json",
  "title": "AI Office Agent Message",
  "type": "object",
  "required": [
    "message_id",
    "from_agent",
    "to_agent",
    "message_type",
    "subject",
    "body",
    "created_at",
    "status"
  ],
  "properties": {
    "message_id": {
      "type": "string",
      "pattern": "^MSG-[0-9]{8}-[0-9]{6}-[A-F0-9]{6}$"
    },
    "from_agent": {
      "type": "string"
    },
    "to_agent": {
      "type": "string"
    },
    "message_type": {
      "type": "string"
    },
    "subject": {
      "type": "string"
    },
    "body": {
      "type": "string"
    },
    "correlation_id": {
      "type": "string"
    },
    "created_at": {
      "type": "string"
    },
    "status": {
      "type": "string"
    }
  }
}
'@

New-SafeFile ".\config\collaboration\agent-message-schema.json" $messageSchema

$delegationSchema = @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://local.ai-office/schemas/delegation-schema.json",
  "title": "AI Office Delegation Record",
  "type": "object",
  "required": [
    "delegation_id",
    "from_agent",
    "to_agent",
    "title",
    "status",
    "priority",
    "depth",
    "created_at",
    "updated_at"
  ],
  "properties": {
    "delegation_id": {
      "type": "string",
      "pattern": "^DEL-[0-9]{8}-[0-9]{6}-[A-F0-9]{6}$"
    },
    "from_agent": {
      "type": "string"
    },
    "to_agent": {
      "type": "string"
    },
    "title": {
      "type": "string"
    },
    "description": {
      "type": "string"
    },
    "status": {
      "type": "string"
    },
    "priority": {
      "type": "integer"
    },
    "depth": {
      "type": "integer",
      "minimum": 0
    },
    "parent_delegation_id": {
      "type": "string"
    },
    "created_at": {
      "type": "string"
    },
    "updated_at": {
      "type": "string"
    }
  }
}
'@

New-SafeFile ".\config\collaboration\delegation-schema.json" $delegationSchema

$index = @'
{
  "version": "1.0.0",
  "updated_at": "",
  "agent_count": 0,
  "available_agent_count": 0,
  "message_count": 0,
  "open_delegation_count": 0,
  "open_conflict_count": 0,
  "agents": [],
  "queues": []
}
'@

New-SafeFile ".\workspace\collaboration\collaboration-index.json" $index

$queueIndex = @'
{
  "version": "1.0.0",
  "updated_at": "",
  "queues": []
}
'@

New-SafeFile ".\workspace\collaboration\queues\queue-index.json" $queueIndex

$agentTemplate = @'
{
  "agent_id": "AGT-EXAMPLE",
  "name": "Example Agent",
  "department": "Operations",
  "role": "Specialist",
  "status": "available",
  "capabilities": [
    "example_capability"
  ],
  "manager_agent_id": "",
  "created_at": "",
  "updated_at": ""
}
'@

New-SafeFile ".\workspace\templates\agent-profile-template.json" $agentTemplate

$common = @'
$script:AIOfficeCollaborationRoot = $null

function Get-AIOfficeCollaborationRoot {
    if (-not [string]::IsNullOrWhiteSpace($script:AIOfficeCollaborationRoot)) {
        return $script:AIOfficeCollaborationRoot
    }

    $resolved = Resolve-Path (Join-Path $PSScriptRoot "..\..")
    $script:AIOfficeCollaborationRoot = $resolved.Path
    return $script:AIOfficeCollaborationRoot
}

function Read-AIOfficeCollaborationJson {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Write-AIOfficeCollaborationJson {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path
    )

    $parent = Split-Path -Parent $Path

    if (-not [string]::IsNullOrWhiteSpace($parent) -and
        -not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $Value |
        ConvertTo-Json -Depth 30 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function ConvertTo-AIOfficeCollaborationArray {
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return @()
    }

    return @($Value | ForEach-Object { $_ })
}

function New-AIOfficeCollaborationId {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("MSG","DEL","CNF","CTX")]
        [string]$Prefix
    )

    $stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $suffix = ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    return $Prefix + "-" + $stamp + "-" + $suffix
}

function Get-AIOfficeAgentPath {
    param([Parameter(Mandatory=$true)][string]$AgentId)

    $root = Get-AIOfficeCollaborationRoot
    return Join-Path $root ("workspace\collaboration\agents\" + $AgentId + ".json")
}

function Get-AIOfficeAgent {
    param([Parameter(Mandatory=$true)][string]$AgentId)

    $path = Get-AIOfficeAgentPath -AgentId $AgentId
    return Read-AIOfficeCollaborationJson -Path $path
}
'@

New-SafeFile ".\scripts\collaboration\AIOfficeCollaboration.Common.ps1" $common

$newAgent = @'
param(
    [Parameter(Mandatory=$true)][string]$AgentId,
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$Department,
    [Parameter(Mandatory=$true)][string]$Role,
    [string[]]$Capabilities = @(),
    [string]$ManagerAgentId = "",
    [string]$Status = "available"
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeCollaboration.Common.ps1")

$root = Get-AIOfficeCollaborationRoot
Set-Location $root

$policy = Read-AIOfficeCollaborationJson `
    -Path ".\config\collaboration\collaboration-policy.json"

if (@($policy.allowed_agent_statuses) -notcontains $Status) {
    throw "Unsupported agent status: $Status"
}

if (-not $AgentId.StartsWith("AGT-")) {
    throw "AgentId must begin with AGT-"
}

$path = Get-AIOfficeAgentPath -AgentId $AgentId

if (Test-Path -LiteralPath $path -PathType Leaf) {
    throw "Agent already exists: $AgentId"
}

$now = (Get-Date).ToString("o")

$agent = [ordered]@{
    agent_id = $AgentId
    name = $Name
    department = $Department
    role = $Role
    status = $Status
    capabilities = @($Capabilities)
    manager_agent_id = $ManagerAgentId
    created_at = $now
    updated_at = $now
}

Write-AIOfficeCollaborationJson -Value $agent -Path $path
& ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1" | Out-Null

Write-Host "Agent created: $AgentId" -ForegroundColor Green
return [pscustomobject]$agent
'@

New-SafeFile ".\scripts\collaboration\New-AIOfficeAgent.ps1" $newAgent

$message = @'
param(
    [Parameter(Mandatory=$true)][string]$FromAgent,
    [Parameter(Mandatory=$true)][string]$ToAgent,
    [Parameter(Mandatory=$true)][string]$Subject,
    [Parameter(Mandatory=$true)][string]$Body,
    [string]$MessageType = "information",
    [string]$CorrelationId = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeCollaboration.Common.ps1")

$root = Get-AIOfficeCollaborationRoot
Set-Location $root

$policy = Read-AIOfficeCollaborationJson `
    -Path ".\config\collaboration\collaboration-policy.json"

if (@($policy.allowed_message_types) -notcontains $MessageType) {
    throw "Unsupported message type: $MessageType"
}

if ($null -eq (Get-AIOfficeAgent -AgentId $FromAgent)) {
    throw "Sender agent not found: $FromAgent"
}

if ($null -eq (Get-AIOfficeAgent -AgentId $ToAgent)) {
    throw "Recipient agent not found: $ToAgent"
}

$messageId = New-AIOfficeCollaborationId -Prefix "MSG"

if ([string]::IsNullOrWhiteSpace($CorrelationId)) {
    $CorrelationId = $messageId
}

$record = [ordered]@{
    message_id = $messageId
    from_agent = $FromAgent
    to_agent = $ToAgent
    message_type = $MessageType
    subject = $Subject
    body = $Body
    correlation_id = $CorrelationId
    created_at = (Get-Date).ToString("o")
    status = "unread"
}

$path = Join-Path ".\workspace\collaboration\messages" ($messageId + ".json")
Write-AIOfficeCollaborationJson -Value $record -Path $path

Write-Host "Agent message sent: $messageId" -ForegroundColor Green
return [pscustomobject]$record
'@

New-SafeFile ".\scripts\collaboration\Send-AIOfficeAgentMessage.ps1" $message

$queue = @'
param(
    [Parameter(Mandatory=$true)][string]$QueueName,
    [Parameter(Mandatory=$true)][string]$ItemType,
    [Parameter(Mandatory=$true)][string]$ReferenceId,
    [int]$Priority = 100,
    [string]$AssignedAgent = "",
    [string]$PayloadJson = "{}"
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeCollaboration.Common.ps1")

$root = Get-AIOfficeCollaborationRoot
Set-Location $root

try {
    $payload = $PayloadJson | ConvertFrom-Json
}
catch {
    throw "PayloadJson is invalid JSON: $($_.Exception.Message)"
}

$queuePath = Join-Path ".\workspace\collaboration\queues" ($QueueName + ".json")
$queue = Read-AIOfficeCollaborationJson -Path $queuePath

if ($null -eq $queue) {
    $queue = [pscustomobject]@{
        queue_name = $QueueName
        updated_at = ""
        items = @()
    }
}

$items = New-Object System.Collections.Generic.List[object]

foreach ($existing in (ConvertTo-AIOfficeCollaborationArray $queue.items)) {
    $items.Add($existing)
}

$item = [ordered]@{
    queue_item_id = "QIT-" + ([guid]::NewGuid().ToString("N").Substring(0,10)).ToUpperInvariant()
    item_type = $ItemType
    reference_id = $ReferenceId
    priority = $Priority
    assigned_agent = $AssignedAgent
    status = "queued"
    created_at = (Get-Date).ToString("o")
    payload = $payload
}

$items.Add($item)

$updatedQueue = [ordered]@{
    queue_name = $QueueName
    updated_at = (Get-Date).ToString("o")
    items = @($items | Sort-Object priority, created_at | ForEach-Object { $_ })
}

Write-AIOfficeCollaborationJson -Value $updatedQueue -Path $queuePath
& ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1" | Out-Null

Write-Host (
    "Queue item added to " +
    $QueueName +
    ": " +
    [string]$item.queue_item_id
) -ForegroundColor Green

return [pscustomobject]$item
'@

New-SafeFile ".\scripts\collaboration\Add-AIOfficeWorkQueueItem.ps1" $queue

$delegation = @'
param(
    [Parameter(Mandatory=$true)][string]$FromAgent,
    [Parameter(Mandatory=$true)][string]$ToAgent,
    [Parameter(Mandatory=$true)][string]$Title,
    [string]$Description = "",
    [int]$Priority = 100,
    [int]$Depth = 0,
    [string]$ParentDelegationId = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeCollaboration.Common.ps1")

$root = Get-AIOfficeCollaborationRoot
Set-Location $root

$policy = Read-AIOfficeCollaborationJson `
    -Path ".\config\collaboration\collaboration-policy.json"

if ($Depth -gt [int]$policy.max_delegation_depth) {
    throw "Maximum delegation depth exceeded."
}

if ($null -eq (Get-AIOfficeAgent -AgentId $FromAgent)) {
    throw "Delegating agent not found: $FromAgent"
}

if ($null -eq (Get-AIOfficeAgent -AgentId $ToAgent)) {
    throw "Recipient agent not found: $ToAgent"
}

$delegationId = New-AIOfficeCollaborationId -Prefix "DEL"
$now = (Get-Date).ToString("o")

$record = [ordered]@{
    delegation_id = $delegationId
    from_agent = $FromAgent
    to_agent = $ToAgent
    title = $Title
    description = $Description
    status = "assigned"
    priority = $Priority
    depth = $Depth
    parent_delegation_id = $ParentDelegationId
    created_at = $now
    updated_at = $now
}

$path = Join-Path ".\workspace\collaboration\delegations" ($delegationId + ".json")
Write-AIOfficeCollaborationJson -Value $record -Path $path

& ".\scripts\collaboration\Add-AIOfficeWorkQueueItem.ps1" `
    -QueueName "delegations" `
    -ItemType "delegation" `
    -ReferenceId $delegationId `
    -Priority $Priority `
    -AssignedAgent $ToAgent `
    -PayloadJson (
        $record |
        ConvertTo-Json -Depth 10 -Compress
    ) |
    Out-Null

Write-Host "Delegation created: $delegationId" -ForegroundColor Green
return [pscustomobject]$record
'@

New-SafeFile ".\scripts\collaboration\New-AIOfficeDelegation.ps1" $delegation

$updateDelegation = @'
param(
    [Parameter(Mandatory=$true)][string]$DelegationId,
    [Parameter(Mandatory=$true)][string]$Status
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeCollaboration.Common.ps1")

$root = Get-AIOfficeCollaborationRoot
Set-Location $root

$policy = Read-AIOfficeCollaborationJson `
    -Path ".\config\collaboration\collaboration-policy.json"

if (@($policy.allowed_delegation_statuses) -notcontains $Status) {
    throw "Unsupported delegation status: $Status"
}

$path = Join-Path ".\workspace\collaboration\delegations" ($DelegationId + ".json")
$record = Read-AIOfficeCollaborationJson -Path $path

if ($null -eq $record) {
    throw "Delegation not found: $DelegationId"
}

$record.status = $Status
$record.updated_at = (Get-Date).ToString("o")

Write-AIOfficeCollaborationJson -Value $record -Path $path
& ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1" | Out-Null

Write-Host (
    "Delegation " +
    $DelegationId +
    " updated to " +
    $Status +
    "."
) -ForegroundColor Green
'@

New-SafeFile ".\scripts\collaboration\Update-AIOfficeDelegation.ps1" $updateDelegation

$context = @'
param(
    [Parameter(Mandatory=$true)][string]$ContextName,
    [Parameter(Mandatory=$true)][string]$OwnerAgent,
    [Parameter(Mandatory=$true)][string]$ContentJson,
    [string[]]$SharedWith = @()
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeCollaboration.Common.ps1")

$root = Get-AIOfficeCollaborationRoot
Set-Location $root

if ($null -eq (Get-AIOfficeAgent -AgentId $OwnerAgent)) {
    throw "Owner agent not found: $OwnerAgent"
}

try {
    $content = $ContentJson | ConvertFrom-Json
}
catch {
    throw "ContentJson is invalid JSON: $($_.Exception.Message)"
}

$contextId = New-AIOfficeCollaborationId -Prefix "CTX"

$record = [ordered]@{
    context_id = $contextId
    context_name = $ContextName
    owner_agent = $OwnerAgent
    shared_with = @($SharedWith)
    content = $content
    created_at = (Get-Date).ToString("o")
    updated_at = (Get-Date).ToString("o")
}

$path = Join-Path ".\workspace\collaboration\shared-context" ($contextId + ".json")
Write-AIOfficeCollaborationJson -Value $record -Path $path

Write-Host "Shared context created: $contextId" -ForegroundColor Green
return [pscustomobject]$record
'@

New-SafeFile ".\scripts\collaboration\New-AIOfficeSharedContext.ps1" $context

$conflict = @'
param(
    [Parameter(Mandatory=$true)][string]$RaisedByAgent,
    [Parameter(Mandatory=$true)][string]$Subject,
    [Parameter(Mandatory=$true)][string]$Description,
    [string[]]$InvolvedAgents = @(),
    [string]$Severity = "medium"
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeCollaboration.Common.ps1")

$root = Get-AIOfficeCollaborationRoot
Set-Location $root

if ($null -eq (Get-AIOfficeAgent -AgentId $RaisedByAgent)) {
    throw "Agent not found: $RaisedByAgent"
}

$conflictId = New-AIOfficeCollaborationId -Prefix "CNF"

$record = [ordered]@{
    conflict_id = $conflictId
    raised_by_agent = $RaisedByAgent
    involved_agents = @($InvolvedAgents)
    subject = $Subject
    description = $Description
    severity = $Severity
    status = "open"
    resolution = ""
    created_at = (Get-Date).ToString("o")
    updated_at = (Get-Date).ToString("o")
}

$path = Join-Path ".\workspace\collaboration\conflicts" ($conflictId + ".json")
Write-AIOfficeCollaborationJson -Value $record -Path $path
& ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1" | Out-Null

Write-Host "Conflict recorded: $conflictId" -ForegroundColor Yellow
return [pscustomobject]$record
'@

New-SafeFile ".\scripts\collaboration\New-AIOfficeConflict.ps1" $conflict

$resolve = @'
param(
    [Parameter(Mandatory=$true)][string]$ConflictId,
    [Parameter(Mandatory=$true)][string]$ResolvedByAgent,
    [Parameter(Mandatory=$true)][string]$Resolution
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeCollaboration.Common.ps1")

$root = Get-AIOfficeCollaborationRoot
Set-Location $root

$path = Join-Path ".\workspace\collaboration\conflicts" ($ConflictId + ".json")
$record = Read-AIOfficeCollaborationJson -Path $path

if ($null -eq $record) {
    throw "Conflict not found: $ConflictId"
}

$record.status = "resolved"
$record.resolution = $Resolution
$record.resolved_by_agent = $ResolvedByAgent
$record.resolved_at = (Get-Date).ToString("o")
$record.updated_at = (Get-Date).ToString("o")

Write-AIOfficeCollaborationJson -Value $record -Path $path
& ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1" | Out-Null

Write-Host "Conflict resolved: $ConflictId" -ForegroundColor Green
'@

New-SafeFile ".\scripts\collaboration\Resolve-AIOfficeConflict.ps1" $resolve

$indexScript = @'
param()

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeCollaboration.Common.ps1")

$root = Get-AIOfficeCollaborationRoot
Set-Location $root

$agents = New-Object System.Collections.Generic.List[object]

foreach ($file in @(
    Get-ChildItem `
        -LiteralPath ".\workspace\collaboration\agents" `
        -Filter "AGT-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    $agent = Read-AIOfficeCollaborationJson -Path $file.FullName

    if ($null -ne $agent) {
        $agents.Add([ordered]@{
            agent_id = [string]$agent.agent_id
            name = [string]$agent.name
            department = [string]$agent.department
            role = [string]$agent.role
            status = [string]$agent.status
            file = $file.Name
        })
    }
}

$queues = New-Object System.Collections.Generic.List[object]

foreach ($file in @(
    Get-ChildItem `
        -LiteralPath ".\workspace\collaboration\queues" `
        -Filter "*.json" `
        -File `
        -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne "queue-index.json" }
)) {
    $queue = Read-AIOfficeCollaborationJson -Path $file.FullName

    if ($null -ne $queue) {
        $items = ConvertTo-AIOfficeCollaborationArray $queue.items
        $queues.Add([ordered]@{
            queue_name = [string]$queue.queue_name
            item_count = [int]$items.Count
            queued_count = [int](@($items | Where-Object { $_.status -eq "queued" }).Count)
            file = $file.Name
        })
    }
}

$messageCount = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\collaboration\messages" `
        -Filter "MSG-*.json" `
        -File `
        -ErrorAction SilentlyContinue
).Count

$openDelegations = 0

foreach ($file in @(
    Get-ChildItem `
        -LiteralPath ".\workspace\collaboration\delegations" `
        -Filter "DEL-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    $record = Read-AIOfficeCollaborationJson -Path $file.FullName

    if ($null -ne $record -and
        [string]$record.status -notin @("completed","rejected","cancelled")) {
        $openDelegations++
    }
}

$openConflicts = 0

foreach ($file in @(
    Get-ChildItem `
        -LiteralPath ".\workspace\collaboration\conflicts" `
        -Filter "CNF-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)) {
    $record = Read-AIOfficeCollaborationJson -Path $file.FullName

    if ($null -ne $record -and [string]$record.status -eq "open") {
        $openConflicts++
    }
}

$availableCount = @(
    $agents | Where-Object { $_.status -eq "available" }
).Count

$index = [ordered]@{
    version = "1.0.0"
    updated_at = (Get-Date).ToString("o")
    agent_count = [int]$agents.Count
    available_agent_count = [int]$availableCount
    message_count = [int]$messageCount
    open_delegation_count = [int]$openDelegations
    open_conflict_count = [int]$openConflicts
    agents = @($agents | Sort-Object department, name | ForEach-Object { $_ })
    queues = @($queues | Sort-Object queue_name | ForEach-Object { $_ })
}

Write-AIOfficeCollaborationJson `
    -Value $index `
    -Path ".\workspace\collaboration\collaboration-index.json"

$queueIndex = [ordered]@{
    version = "1.0.0"
    updated_at = (Get-Date).ToString("o")
    queues = @($queues | Sort-Object queue_name | ForEach-Object { $_ })
}

Write-AIOfficeCollaborationJson `
    -Value $queueIndex `
    -Path ".\workspace\collaboration\queues\queue-index.json"

Write-Host (
    "Collaboration index updated: " +
    $agents.Count.ToString() +
    " agent(s), " +
    $openDelegations.ToString() +
    " open delegation(s)."
) -ForegroundColor Green

return [pscustomobject]$index
'@

New-SafeFile ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1" $indexScript

$show = @'
param()

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "AIOfficeCollaboration.Common.ps1")

$root = Get-AIOfficeCollaborationRoot
Set-Location $root

$index = & ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1"

Write-Host ""
Write-Host "AI OFFICE AGENT COLLABORATION STATUS" -ForegroundColor Cyan
Write-Host ("=" * 72)
Write-Host (
    "Agents: " +
    [string]$index.agent_count +
    " total | " +
    [string]$index.available_agent_count +
    " available"
)
Write-Host (
    "Messages: " +
    [string]$index.message_count
)
Write-Host (
    "Delegations: " +
    [string]$index.open_delegation_count +
    " open"
)
Write-Host (
    "Conflicts: " +
    [string]$index.open_conflict_count +
    " open"
)
Write-Host ""

foreach ($agent in @($index.agents)) {
    Write-Host (
        [string]$agent.agent_id +
        " | " +
        [string]$agent.department +
        " | " +
        [string]$agent.role +
        " | " +
        [string]$agent.status
    )
}

Write-Host ""
return $index
'@

New-SafeFile ".\scripts\collaboration\Show-AIOfficeCollaborationStatus.ps1" $show

$test = @'
param()

$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $root.Path

Write-Host ""
Write-Host "Testing AI Office agent collaboration layer..." -ForegroundColor Cyan
Write-Host ""

$errors = New-Object System.Collections.Generic.List[string]

$jsonFiles = @(
    ".\config\collaboration\collaboration-policy.json",
    ".\config\collaboration\agent-profile-schema.json",
    ".\config\collaboration\agent-message-schema.json",
    ".\config\collaboration\delegation-schema.json",
    ".\workspace\collaboration\collaboration-index.json",
    ".\workspace\collaboration\queues\queue-index.json",
    ".\workspace\templates\agent-profile-template.json"
)

foreach ($file in $jsonFiles) {
    try {
        Get-Content -LiteralPath $file -Raw |
            ConvertFrom-Json |
            Out-Null
        Write-Host "[VALID JSON] $file" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $file" -ForegroundColor Red
        $errors.Add("Invalid JSON: " + $file)
    }
}

$scripts = @(
    ".\scripts\collaboration\AIOfficeCollaboration.Common.ps1",
    ".\scripts\collaboration\New-AIOfficeAgent.ps1",
    ".\scripts\collaboration\Send-AIOfficeAgentMessage.ps1",
    ".\scripts\collaboration\Add-AIOfficeWorkQueueItem.ps1",
    ".\scripts\collaboration\New-AIOfficeDelegation.ps1",
    ".\scripts\collaboration\Update-AIOfficeDelegation.ps1",
    ".\scripts\collaboration\New-AIOfficeSharedContext.ps1",
    ".\scripts\collaboration\New-AIOfficeConflict.ps1",
    ".\scripts\collaboration\Resolve-AIOfficeConflict.ps1",
    ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1",
    ".\scripts\collaboration\Show-AIOfficeCollaborationStatus.ps1",
    ".\scripts\collaboration\Test-AIOfficeCollaboration.ps1"
)

foreach ($script in $scripts) {
    if (Test-Path -LiteralPath $script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING    ] $script" -ForegroundColor Red
        $errors.Add("Missing script: " + $script)
    }
}

$chief = "AGT-VALIDATION-CHIEF"
$marketing = "AGT-VALIDATION-MARKETING"

foreach ($agentId in @($chief, $marketing)) {
    $path = ".\workspace\collaboration\agents\$agentId.json"

    if (Test-Path -LiteralPath $path -PathType Leaf) {
        Remove-Item -LiteralPath $path -Force
    }
}

try {
    & ".\scripts\collaboration\New-AIOfficeAgent.ps1" `
        -AgentId $chief `
        -Name "Validation Chief of Staff" `
        -Department "Executive" `
        -Role "Chief of Staff" `
        -Capabilities @("coordination","escalation") |
        Out-Null

    & ".\scripts\collaboration\New-AIOfficeAgent.ps1" `
        -AgentId $marketing `
        -Name "Validation Marketing Agent" `
        -Department "Marketing" `
        -Role "Marketing Specialist" `
        -Capabilities @("campaigns","creative") `
        -ManagerAgentId $chief |
        Out-Null

    Write-Host "[AGENT OK   ] Agent registration passed." -ForegroundColor Green
}
catch {
    Write-Host "[AGENT ERR  ] Agent registration failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errors.Add("Agent registration failed: " + $_.Exception.Message)
}

try {
    $message = & ".\scripts\collaboration\Send-AIOfficeAgentMessage.ps1" `
        -FromAgent $chief `
        -ToAgent $marketing `
        -MessageType "request" `
        -Subject "Validation request" `
        -Body "Prepare the validation handoff."

    if ($null -eq $message -or
        [string]::IsNullOrWhiteSpace([string]$message.message_id)) {
        throw "Message did not contain a message_id."
    }

    Write-Host (
        "[MESSAGE OK ] " +
        [string]$message.message_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[MESSAGE ERR] Agent messaging failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errors.Add("Agent messaging failed: " + $_.Exception.Message)
}

$delegationId = ""

try {
    $delegation = & ".\scripts\collaboration\New-AIOfficeDelegation.ps1" `
        -FromAgent $chief `
        -ToAgent $marketing `
        -Title "Validation delegation" `
        -Description "Complete Package 14 validation." `
        -Priority 1

    $delegationId = [string]$delegation.delegation_id

    if ([string]::IsNullOrWhiteSpace($delegationId)) {
        throw "Delegation did not contain an ID."
    }

    & ".\scripts\collaboration\Update-AIOfficeDelegation.ps1" `
        -DelegationId $delegationId `
        -Status "completed" |
        Out-Null

    Write-Host (
        "[DELEGATE OK] " +
        $delegationId
    ) -ForegroundColor Green
}
catch {
    Write-Host "[DELEGATE ER] Delegation failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errors.Add("Delegation failed: " + $_.Exception.Message)
}

try {
    $context = & ".\scripts\collaboration\New-AIOfficeSharedContext.ps1" `
        -ContextName "Validation context" `
        -OwnerAgent $chief `
        -SharedWith @($marketing) `
        -ContentJson '{"project":"Package 14","status":"validation"}'

    if ([string]::IsNullOrWhiteSpace([string]$context.context_id)) {
        throw "Shared context did not contain an ID."
    }

    Write-Host (
        "[CONTEXT OK ] " +
        [string]$context.context_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[CONTEXT ERR] Shared context failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errors.Add("Shared context failed: " + $_.Exception.Message)
}

try {
    $conflict = & ".\scripts\collaboration\New-AIOfficeConflict.ps1" `
        -RaisedByAgent $marketing `
        -Subject "Validation conflict" `
        -Description "Temporary conflict used for testing." `
        -InvolvedAgents @($chief, $marketing)

    & ".\scripts\collaboration\Resolve-AIOfficeConflict.ps1" `
        -ConflictId ([string]$conflict.conflict_id) `
        -ResolvedByAgent $chief `
        -Resolution "Resolved during validation." |
        Out-Null

    Write-Host (
        "[CONFLICT OK] " +
        [string]$conflict.conflict_id
    ) -ForegroundColor Green
}
catch {
    Write-Host "[CONFLICT ER] Conflict workflow failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errors.Add("Conflict workflow failed: " + $_.Exception.Message)
}

try {
    $index = & ".\scripts\collaboration\Update-AIOfficeCollaborationIndex.ps1"

    if ($null -eq $index -or [int]$index.agent_count -lt 2) {
        throw "Collaboration index did not contain validation agents."
    }

    Write-Host (
        "[INDEX OK   ] " +
        [string]$index.agent_count +
        " agent(s)"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[INDEX ERR  ] Collaboration index failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $errors.Add("Collaboration index failed: " + $_.Exception.Message)
}

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $errors.Count.ToString() +
        " collaboration error or errors were found."
    ) -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All agent collaboration checks passed." -ForegroundColor Green
'@

New-SafeFile ".\scripts\collaboration\Test-AIOfficeCollaboration.ps1" $test

$guide = @'
# AI Office Package 14 — Agent Collaboration Layer

Package 14 turns AI Office into a coordinated multi-agent organization.

## Capabilities

- Agent registration and status tracking
- Department and role definitions
- Capability-based agent profiles
- Agent-to-agent messaging
- Shared work queues
- Delegation and handoff records
- Delegation depth protection
- Shared context records
- Conflict tracking and resolution
- Escalation-ready structures
- Collaboration index and status display

## Register an agent

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\collaboration\New-AIOfficeAgent.ps1" `
    -AgentId "AGT-MARKETING" `
    -Name "Marketing Agent" `
    -Department "Marketing" `
    -Role "Marketing Director" `
    -Capabilities @("campaigns","content","strategy")
```

## Send a message

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\collaboration\Send-AIOfficeAgentMessage.ps1" `
    -FromAgent "AGT-CHIEF-OF-STAFF" `
    -ToAgent "AGT-MARKETING" `
    -MessageType "request" `
    -Subject "Campaign brief" `
    -Body "Prepare a campaign plan and delegate creative production."
```

## Create a delegation

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\collaboration\New-AIOfficeDelegation.ps1" `
    -FromAgent "AGT-CHIEF-OF-STAFF" `
    -ToAgent "AGT-MARKETING" `
    -Title "Prepare campaign" `
    -Priority 25
```

## Show collaboration status

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\collaboration\Show-AIOfficeCollaborationStatus.ps1"
```

## Validation

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\collaboration\Test-AIOfficeCollaboration.ps1"
```

Expected result:

```text
All agent collaboration checks passed.
```

Package 15 will connect the automation engine, executive dashboard, calendar, workflows, knowledge, and this collaboration layer into the complete AI Office Executive Operating System.
'@

New-SafeFile ".\docs\Agent-Collaboration-Guide.md" $guide

Write-Host ""
Write-Host "Validating Package 14 JSON files..." -ForegroundColor Cyan

$validationFiles = @(
    ".\config\collaboration\collaboration-policy.json",
    ".\config\collaboration\agent-profile-schema.json",
    ".\config\collaboration\agent-message-schema.json",
    ".\config\collaboration\delegation-schema.json",
    ".\workspace\collaboration\collaboration-index.json",
    ".\workspace\collaboration\queues\queue-index.json",
    ".\workspace\templates\agent-profile-template.json"
)

foreach ($file in $validationFiles) {
    try {
        Get-Content -LiteralPath $file -Raw |
            ConvertFrom-Json |
            Out-Null
        Write-Host "[VALID JSON] $file" -ForegroundColor Green
    }
    catch {
        throw (
            "Package 14 JSON validation failed for " +
            $file +
            ": " +
            $_.Exception.Message
        )
    }
}

try {
    $source = $MyInvocation.MyCommand.Path

    if (-not [string]::IsNullOrWhiteSpace($source) -and
        (Test-Path -LiteralPath $source -PathType Leaf)) {
        $destination = Join-Path `
            $repository `
            "Installers\AI-Office-Package-14-Install.ps1"

        if ([System.IO.Path]::GetFullPath($source) -ne
            [System.IO.Path]::GetFullPath($destination)) {
            Copy-Item `
                -LiteralPath $source `
                -Destination $destination `
                -Force

            Write-Host (
                "[COPIED ] Installer saved to " +
                $destination
            ) -ForegroundColor Green
        }
        else {
            Write-Host "[EXISTS ] Installer is already in the Installers folder." `
                -ForegroundColor DarkGray
        }
    }
}
catch {
    Write-Host (
        "[WARNING] Installer copy was not completed: " +
        $_.Exception.Message
    ) -ForegroundColor Yellow
}

Write-Host ""
Write-Host "AI Office Package 14 installation completed." -ForegroundColor Green
Write-Host ""
Write-Host "Run validation with:" -ForegroundColor Cyan
Write-Host ""
Write-Host 'powershell -ExecutionPolicy Bypass -File `'
Write-Host '    ".\scripts\collaboration\Test-AIOfficeCollaboration.ps1"'
Write-Host ""
