param(
    [Parameter(Mandatory=$true)][string]$IdeaId,
    [Parameter(Mandatory=$true)][string]$Name,
    [double]$Budget = 0.0,
    [string]$MilestonesJson = "[]"
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\business-incubator\AIOfficeBusinessIncubator.Common.ps1"

$Idea = Read-AIOfficeBusinessJson `
    -Path "E:\AI\AI-Office\workspace\business-incubator\ideas\$IdeaId.json"

if ($null -eq $Idea) {
    throw "Business idea not found: $IdeaId"
}

try {
    $Milestones = @((ConvertFrom-Json -InputObject $MilestonesJson) | ForEach-Object { $_ })
}
catch {
    throw "MilestonesJson is invalid JSON."
}

$Id = New-AIOfficeBusinessId -Prefix "BIZLAUNCH"
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    launch_plan_id = $Id
    idea_id = $IdeaId
    idea_name = [string]$Idea.name
    name = $Name
    budget = [math]::Round([math]::Abs($Budget),2)
    milestones = $Milestones
    status = "draft"
    created_at = $Now
    updated_at = $Now
}

Write-AIOfficeBusinessJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\business-incubator\launch-plans\$Id.json"

& "E:\AI\AI-Office\scripts\business-incubator\Update-AIOfficeBusinessIncubatorIndex.ps1" | Out-Null

Write-Host "Launch plan created: $Id | $Name" -ForegroundColor Green
return [pscustomobject]$Record
