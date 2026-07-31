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
