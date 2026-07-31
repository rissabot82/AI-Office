param(
    [string]$Query = "",
    [string]$Scope = "",
    [string]$Department = "",
    [string]$MemoryType = "",
    [string]$Project = "",
    [string]$Entity = "",
    [string]$Status = "active",
    [double]$MinimumConfidence = 0.0,
    [int]$Limit = 25,
    [switch]$TrackAccess
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryRecall.Common.ps1")

$Root = Get-AIOfficeMemoryRoot
Set-Location $Root

$Policy = Get-AIOfficeMemoryCaptureRecallPolicy

if ($Limit -lt 1) {
    $Limit = 1
}

if ($Limit -gt [int]$Policy.search.maximum_limit) {
    $Limit = [int]$Policy.search.maximum_limit
}

$Results = New-Object System.Collections.Generic.List[object]

foreach ($File in @(Get-AIOfficeAllMemoryFiles)) {
    $Record = Read-AIOfficeMemoryJson -Path $File.FullName

    if ($null -eq $Record) {
        continue
    }

    if ($Scope -and [string]$Record.scope -ne $Scope) {
        continue
    }

    if ($Department -and [string]$Record.department -ne $Department) {
        continue
    }

    if ($MemoryType -and [string]$Record.memory_type -ne $MemoryType) {
        continue
    }

    if ($Status -and [string]$Record.status -ne $Status) {
        continue
    }

    if ([double]$Record.confidence -lt $MinimumConfidence) {
        continue
    }

    if ($Project -and @($Record.projects) -notcontains $Project) {
        continue
    }

    if ($Entity -and @($Record.entities) -notcontains $Entity) {
        continue
    }

    if ($Query) {
        $SearchText = Get-AIOfficeMemorySearchText -Record $Record

        if (-not $SearchText.Contains($Query.ToLowerInvariant())) {
            continue
        }
    }

    if ($TrackAccess -or [bool]$Policy.search.track_access) {
        $Record.access_count = [int]$Record.access_count + 1
        $Record.last_accessed_at = (Get-Date).ToString("o")
        $Record.updated_at = (Get-Date).ToString("o")

        Write-AIOfficeMemoryJson `
            -Value $Record `
            -Path $File.FullName
    }

    $Results.Add([pscustomobject]@{
        memory_id = [string]$Record.memory_id
        scope = [string]$Record.scope
        department = [string]$Record.department
        memory_type = [string]$Record.memory_type
        title = [string]$Record.title
        summary = [string]$Record.summary
        confidence = [double]$Record.confidence
        status = [string]$Record.status
        tags = @($Record.tags)
        entities = @($Record.entities)
        projects = @($Record.projects)
        access_count = [int]$Record.access_count
        updated_at = [string]$Record.updated_at
        source_path = $File.FullName
    })
}

return @(
    $Results |
        Sort-Object confidence, access_count, updated_at -Descending |
        Select-Object -First $Limit
)
