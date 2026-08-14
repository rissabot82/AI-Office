param(
 [Parameter(Mandatory=$true)][string]$Content,
 [string]$Title="User-approved conversation memory",
 [string]$Scope="global"
)
$ErrorActionPreference="Stop"
$Policy=Get-Content "E:\AI\AI-Office\config\memory\capture-policy.json" -Raw|ConvertFrom-Json

$Capture=& "E:\AI\AI-Office\scripts\memory\Get-AIOfficeExplicitMemoryCapture.ps1" -Content $Content
if(-not [bool]$Capture.capture){
 return [pscustomobject]@{captured=$false;memory_id="";reason="no_explicit_memory_intent"}
}

$Saved=& "E:\AI\AI-Office\scripts\memory\Save-AIOfficeMemoryRecord.ps1" `
 -MemoryType ([string]$Policy.default_memory_type) `
 -Title $Title `
 -Content ([string]$Capture.content) `
 -Source ([string]$Policy.source) `
 -Scope $Scope

return [pscustomobject]@{
 captured=[bool]$Saved.created
 memory_id=[string]$Saved.memory_id
 duplicate=[bool]$Saved.duplicate
 content=[string]$Capture.content
 matched_phrase=[string]$Capture.matched_phrase
}
