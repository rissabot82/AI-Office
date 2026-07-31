param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeMemoryLearning.Common.ps1")

$Records = @(
    foreach ($File in @(Get-AIOfficeAllMemoryFiles)) {
        $Record = Read-AIOfficeMemoryJson -Path $File.FullName

        if ($null -ne $Record) {
            $Record
        }
    }
)

$Conflicts = New-Object System.Collections.Generic.List[object]

for ($i = 0; $i -lt $Records.Count; $i++) {
    for ($j = $i + 1; $j -lt $Records.Count; $j++) {
        $A = $Records[$i]
        $B = $Records[$j]

        $SharedEntities = @(
            $A.entities | Where-Object { @($B.entities) -contains $_ }
        )

        $SharedProjects = @(
            $A.projects | Where-Object { @($B.projects) -contains $_ }
        )

        if ($SharedEntities.Count -lt 1 -and $SharedProjects.Count -lt 1) {
            continue
        }

        if ([string]$A.memory_type -ne [string]$B.memory_type) {
            continue
        }

        if ([string]$A.summary -eq [string]$B.summary) {
            continue
        }

        $Conflict = [ordered]@{
            conflict_id = New-AIOfficeMemoryConflictId
            memory_ids = @(
                [string]$A.memory_id,
                [string]$B.memory_id
            )
            reason = "Memories share entities or projects but contain different summaries."
            shared_entities = $SharedEntities
            shared_projects = $SharedProjects
            status = "open"
            created_at = (Get-Date).ToString("o")
        }

        Write-AIOfficeMemoryJson `
            -Value $Conflict `
            -Path (
                ".\workspace\memory\conflicts\" +
                [string]$Conflict.conflict_id +
                ".json"
            )

        $Conflicts.Add([pscustomobject]$Conflict)
    }
}

return @($Conflicts | ForEach-Object { $_ })
