param(
    [Parameter(Mandatory=$true)][string]$Department,
    [ValidateSet("lesson","template","playbook","decision","metric")]
    [string]$KnowledgeType,
    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][string]$Summary,
    [Parameter(Mandatory=$true)][string]$ContentJson,
    [Parameter(Mandatory=$true)][string]$SourceJson,
    [ValidateRange(0.0,1.0)]
    [double]$Confidence = 0.75
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentKnowledge.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

Get-AIOfficeDepartmentProfile -Department $Department | Out-Null

try {
    $Content = $ContentJson | ConvertFrom-Json
}
catch {
    throw "ContentJson is invalid: $($_.Exception.Message)"
}

try {
    $Source = $SourceJson | ConvertFrom-Json
}
catch {
    throw "SourceJson is invalid: $($_.Exception.Message)"
}

$KnowledgeId = New-AIOfficeDepartmentKnowledgeId
$Now = (Get-Date).ToString("o")

$Record = [ordered]@{
    knowledge_id = $KnowledgeId
    department = $Department
    knowledge_type = $KnowledgeType
    title = $Title
    summary = $Summary
    content = $Content
    source = $Source
    confidence = $Confidence
    created_at = $Now
    updated_at = $Now
    reuse_count = 0
    success_count = 0
    failure_count = 0
    history = @(
        [ordered]@{
            timestamp = $Now
            action = "created"
            actor = $Department
            details = "Department knowledge item created."
        }
    )
}

$Folder = Get-AIOfficeDepartmentKnowledgeFolder `
    -Department $Department `
    -KnowledgeType $KnowledgeType

$Path = Join-Path $Folder ($KnowledgeId + ".json")

Write-AIOfficeDepartmentJson -Value $Record -Path $Path

& ".\scripts\departments\Update-AIOfficeDepartmentIndex.ps1" |
    Out-Null

Write-Host "Department knowledge created: $KnowledgeId" `
    -ForegroundColor Green

return [pscustomobject]$Record
