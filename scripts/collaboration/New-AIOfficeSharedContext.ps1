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
