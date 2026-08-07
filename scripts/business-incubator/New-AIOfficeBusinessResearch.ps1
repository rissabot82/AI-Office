param(
    [Parameter(Mandatory=$true)][string]$IdeaId,
    [Parameter(Mandatory=$true)][string]$ResearchType,
    [Parameter(Mandatory=$true)][string]$Summary,
    [string]$SourcesJson = "[]",
    [string]$FindingsJson = "{}"
)

$ErrorActionPreference = "Stop"
. "E:\AI\AI-Office\scripts\business-incubator\AIOfficeBusinessIncubator.Common.ps1"

$Idea = Read-AIOfficeBusinessJson `
    -Path "E:\AI\AI-Office\workspace\business-incubator\ideas\$IdeaId.json"

if ($null -eq $Idea) {
    throw "Business idea not found: $IdeaId"
}

try {
    $Sources = @((ConvertFrom-Json -InputObject $SourcesJson) | ForEach-Object { $_ })
    $Findings = ConvertFrom-Json -InputObject $FindingsJson
}
catch {
    throw "SourcesJson or FindingsJson is invalid JSON."
}

$Id = New-AIOfficeBusinessId -Prefix "BIZRES"

$Record = [ordered]@{
    research_id = $Id
    idea_id = $IdeaId
    idea_name = [string]$Idea.name
    research_type = $ResearchType
    summary = $Summary
    sources = $Sources
    findings = $Findings
    created_at = (Get-Date).ToString("o")
}

Write-AIOfficeBusinessJson `
    -Value $Record `
    -Path "E:\AI\AI-Office\workspace\business-incubator\research\$Id.json"

& "E:\AI\AI-Office\scripts\business-incubator\Update-AIOfficeBusinessIncubatorIndex.ps1" | Out-Null

Write-Host "Business research created: $Id | $ResearchType" -ForegroundColor Green
return [pscustomobject]$Record
