$script:AIOfficeKnowledgeReasoningRoot = "E:\AI\AI-Office"

function Get-AIOfficeKnowledgeReasoningRoot {
    return $script:AIOfficeKnowledgeReasoningRoot
}

function Get-AIOfficeKnowledgeReasoningPolicy {
    return Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\knowledge-graph\reasoning-policy.json" `
        -Raw |
        ConvertFrom-Json
}

function Normalize-AIOfficeKnowledgeName {
    param([Parameter(Mandatory=$true)][string]$Name)

    $Value = $Name.Trim().ToLowerInvariant()
    $Value = [regex]::Replace($Value, "[^\p{L}\p{Nd}\s\-]", "")
    $Value = [regex]::Replace($Value, "\s+", " ")

    return $Value
}

function New-AIOfficeKnowledgeInferenceId {
    return (
        "KGI-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeKnowledgeContradictionId {
    return (
        "KGC-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeKnowledgeDecisionScoreId {
    return (
        "KGD-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeKnowledgeAllEntities {
    . "E:\AI\AI-Office\scripts\knowledge-graph\AIOfficeKnowledgeGraph.Common.ps1"

    return @(
        foreach ($File in @(
            Get-ChildItem `
                -LiteralPath "E:\AI\AI-Office\workspace\knowledge-graph\entities" `
                -Filter "KGE-*.json" `
                -File `
                -ErrorAction SilentlyContinue
        )) {
            $Record = Read-AIOfficeKnowledgeGraphJson -Path $File.FullName

            if ($null -ne $Record) {
                $Record
            }
        }
    )
}

function Get-AIOfficeKnowledgeAllRelationships {
    . "E:\AI\AI-Office\scripts\knowledge-graph\AIOfficeKnowledgeGraph.Common.ps1"

    return @(
        foreach ($File in @(
            Get-ChildItem `
                -LiteralPath "E:\AI\AI-Office\workspace\knowledge-graph\relationships" `
                -Filter "KGR-*.json" `
                -File `
                -ErrorAction SilentlyContinue
        )) {
            $Record = Read-AIOfficeKnowledgeGraphJson -Path $File.FullName

            if ($null -ne $Record) {
                $Record
            }
        }
    )
}

function Find-AIOfficeKnowledgeEntityByName {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [string]$EntityType = ""
    )

    $Normalized = Normalize-AIOfficeKnowledgeName -Name $Name

    foreach ($Entity in @(Get-AIOfficeKnowledgeAllEntities)) {
        if ($EntityType -and [string]$Entity.entity_type -ne $EntityType) {
            continue
        }

        if ((Normalize-AIOfficeKnowledgeName -Name ([string]$Entity.name)) -eq $Normalized) {
            return $Entity
        }

        foreach ($Alias in @($Entity.aliases)) {
            if ((Normalize-AIOfficeKnowledgeName -Name ([string]$Alias)) -eq $Normalized) {
                return $Entity
            }
        }
    }

    return $null
}
