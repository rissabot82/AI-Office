param(
    [Parameter(Mandatory=$true)][string]$Department,
    [string]$Query = "",
    [string]$KnowledgeType = "",
    [double]$MinimumConfidence = 0.0,
    [int]$Limit = 25
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeDepartmentKnowledge.Common.ps1")

$Root = Get-AIOfficeDepartmentRoot
Set-Location $Root

$Results = New-Object System.Collections.Generic.List[object]
$Base = ".\workspace\departments\$Department\knowledge"

foreach ($Folder in @(
    "lessons",
    "templates",
    "playbooks",
    "decisions",
    "metrics"
)) {
    foreach ($File in @(
        Get-ChildItem `
            -LiteralPath "$Base\$Folder" `
            -Filter "DKI-*.json" `
            -File `
            -ErrorAction SilentlyContinue
    )) {
        $Record = Read-AIOfficeDepartmentJson -Path $File.FullName

        if ($null -eq $Record) {
            continue
        }

        if ($KnowledgeType -and
            [string]$Record.knowledge_type -ne $KnowledgeType) {
            continue
        }

        if ([double]$Record.confidence -lt $MinimumConfidence) {
            continue
        }

        if ($Query) {
            $SearchText = (
                [string]$Record.title +
                " " +
                [string]$Record.summary +
                " " +
                ($Record.content | ConvertTo-Json -Depth 20 -Compress)
            ).ToLowerInvariant()

            if (-not $SearchText.Contains($Query.ToLowerInvariant())) {
                continue
            }
        }

        $Results.Add([pscustomobject]@{
            knowledge_id = [string]$Record.knowledge_id
            department = [string]$Record.department
            knowledge_type = [string]$Record.knowledge_type
            title = [string]$Record.title
            summary = [string]$Record.summary
            confidence = [double]$Record.confidence
            reuse_count = [int]$Record.reuse_count
            success_count = [int]$Record.success_count
            failure_count = [int]$Record.failure_count
            updated_at = [string]$Record.updated_at
        })
    }
}

return @(
    $Results |
        Sort-Object confidence, reuse_count, updated_at -Descending |
        Select-Object -First $Limit
)
