param(
    [string]$Query = "",
    [string]$Scope = "",
    [string]$Department = "",
    [string]$Project = "",
    [string]$Entity = "",
    [string]$RequestedBy = "chief-of-staff",
    [int]$Limit = 10
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryRecall.Common.ps1")

$Root = Get-AIOfficeMemoryRoot
Set-Location $Root

$SearchArgs = @{
    Query = $Query
    Scope = $Scope
    Department = $Department
    Project = $Project
    Entity = $Entity
    Limit = $Limit
    TrackAccess = $true
}

$SearchArgs = @{}
if ($Query) { $SearchArgs.Query = $Query }
if ($Scope) { $SearchArgs.Scope = $Scope }
if ($Department) { $SearchArgs.Department = $Department }
if ($Project) { $SearchArgs.Project = $Project }
if ($Entity) { $SearchArgs.Entity = $Entity }
$SearchArgs.Limit = $Limit
$SearchArgs.TrackAccess = $true

$SearchResults = @(
    & ".\scripts\memory\Search-AIOfficeMemory.ps1" @SearchArgs
)

$Memories = New-Object System.Collections.Generic.List[object]

foreach ($SearchResult in $SearchResults) {
    $Record = & ".\scripts\memory\Get-AIOfficeMemory.ps1" `
        -MemoryId ([string]$SearchResult.memory_id)

    $Memories.Add($Record)
}

$PacketId = New-AIOfficeMemoryContextPacketId

$Packet = [ordered]@{
    context_packet_id = $PacketId
    created_at = (Get-Date).ToString("o")
    requested_by = $RequestedBy
    query = $Query
    scope = $Scope
    department = $Department
    project = $Project
    entity = $Entity
    memory_count = $Memories.Count
    memories = @($Memories | ForEach-Object { $_ })
}

$Path = Join-Path `
    ".\workspace\memory\context-packets" `
    ($PacketId + ".json")

Write-AIOfficeMemoryJson -Value $Packet -Path $Path

Write-Host (
    "Memory context packet created: " +
    $PacketId +
    " | " +
    $Memories.Count.ToString() +
    " memory record(s)"
) -ForegroundColor Green

return [pscustomobject]$Packet
