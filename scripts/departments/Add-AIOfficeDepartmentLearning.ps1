param(
    [Parameter(Mandatory=$true)][string]$Department,
    [ValidateSet("success","failure","revision","approval","reuse")]
    [string]$EventType,
    [Parameter(Mandatory=$true)][string]$SourceId,
    [Parameter(Mandatory=$true)][string]$Summary,
    [string]$KnowledgeId = ""
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentKnowledge.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$LearningId = New-AIOfficeDepartmentLearningId
$Now = (Get-Date).ToString("o")

$Outcome = switch ($EventType) {
    "success" { "successful" }
    "failure" { "failed" }
    "revision" { "revised" }
    "approval" { "approved" }
    "reuse" { "reused" }
}

$Record = [ordered]@{
    learning_id = $LearningId
    department = $Department
    event_type = $EventType
    source_id = $SourceId
    knowledge_id = $KnowledgeId
    outcome = $Outcome
    summary = $Summary
    created_at = $Now
}

$Path = Join-Path `
    ".\workspace\departments\$Department\learning" `
    ($LearningId + ".json")

Write-AIOfficeDepartmentJson -Value $Record -Path $Path

if (-not [string]::IsNullOrWhiteSpace($KnowledgeId)) {
    $Knowledge = Get-AIOfficeDepartmentKnowledgeItem `
        -Department $Department `
        -KnowledgeId $KnowledgeId

    switch ($EventType) {
        "success" { $Knowledge.success_count = [int]$Knowledge.success_count + 1 }
        "failure" { $Knowledge.failure_count = [int]$Knowledge.failure_count + 1 }
        "reuse" { $Knowledge.reuse_count = [int]$Knowledge.reuse_count + 1 }
    }

    $Knowledge.updated_at = $Now

    $History = New-Object System.Collections.Generic.List[object]

    foreach ($Entry in @($Knowledge.history)) {
        $History.Add($Entry)
    }

    $History.Add([ordered]@{
        timestamp = $Now
        action = $EventType
        actor = $Department
        details = $Summary
    })

    $Knowledge.history = @($History | ForEach-Object { $_ })

    $Folder = Get-AIOfficeDepartmentKnowledgeFolder `
        -Department $Department `
        -KnowledgeType ([string]$Knowledge.knowledge_type)

    Write-AIOfficeDepartmentJson `
        -Value $Knowledge `
        -Path (Join-Path $Folder ($KnowledgeId + ".json"))
}

Write-Host "Department learning recorded: $LearningId" `
    -ForegroundColor Green

return [pscustomobject]$Record
