param(
    [Parameter(Mandatory=$true)][string]$MemoryId,
    [int]$Limit = 10
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryRecall.Common.ps1")

$Source = & ".\scripts\memory\Get-AIOfficeMemory.ps1" `
    -MemoryId $MemoryId

$Results = New-Object System.Collections.Generic.List[object]

foreach ($File in @(Get-AIOfficeAllMemoryFiles)) {
    if ($File.BaseName -eq $MemoryId) {
        continue
    }

    $Record = Read-AIOfficeMemoryJson -Path $File.FullName

    if ($null -eq $Record) {
        continue
    }

    $SharedTags = @($Source.tags | Where-Object { @($Record.tags) -contains $_ })
    $SharedEntities = @($Source.entities | Where-Object { @($Record.entities) -contains $_ })
    $SharedProjects = @($Source.projects | Where-Object { @($Record.projects) -contains $_ })

    $Score = $SharedTags.Count + $SharedEntities.Count + $SharedProjects.Count

    if ($Score -lt 1) {
        continue
    }

    $Results.Add([pscustomobject]@{
        memory_id = [string]$Record.memory_id
        title = [string]$Record.title
        scope = [string]$Record.scope
        department = [string]$Record.department
        relation_score = $Score
        shared_tags = $SharedTags
        shared_entities = $SharedEntities
        shared_projects = $SharedProjects
    })
}

$Sorted = @(
    $Results |
        Sort-Object relation_score -Descending |
        Select-Object -First $Limit
)

$Record = [ordered]@{
    related_check_id = (
        "RELMEM-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
    source_memory_id = $MemoryId
    created_at = (Get-Date).ToString("o")
    related_count = $Sorted.Count
    related_memories = $Sorted
}

Write-AIOfficeMemoryJson `
    -Value $Record `
    -Path (
        ".\workspace\memory\related\" +
        [string]$Record.related_check_id +
        ".json"
    )

return [pscustomobject]$Record
