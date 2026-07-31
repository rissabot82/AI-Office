. (Join-Path $PSScriptRoot "AIOfficeDepartments.Common.ps1")

function Get-AIOfficeDepartmentKnowledgePolicy {
    $Root = Get-AIOfficeDepartmentRoot

    return Read-AIOfficeDepartmentJson `
        -Path (Join-Path $Root "config\departments\department-knowledge-policy.json")
}

function New-AIOfficeDepartmentKnowledgeId {
    return (
        "DKI-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeDepartmentLearningId {
    return (
        "DLR-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeDepartmentKnowledgeFolder {
    param(
        [Parameter(Mandatory=$true)][string]$Department,
        [Parameter(Mandatory=$true)][string]$KnowledgeType
    )

    $Root = Get-AIOfficeDepartmentRoot

    $FolderName = switch ($KnowledgeType) {
        "lesson" { "lessons" }
        "template" { "templates" }
        "playbook" { "playbooks" }
        "decision" { "decisions" }
        "metric" { "metrics" }
        default { "lessons" }
    }

    return Join-Path `
        $Root `
        ("workspace\departments\" + $Department + "\knowledge\" + $FolderName)
}

function Get-AIOfficeDepartmentKnowledgeItem {
    param(
        [Parameter(Mandatory=$true)][string]$Department,
        [Parameter(Mandatory=$true)][string]$KnowledgeId
    )

    $Base = Join-Path `
        (Get-AIOfficeDepartmentRoot) `
        ("workspace\departments\" + $Department + "\knowledge")

    foreach ($Folder in @(
        "lessons",
        "templates",
        "playbooks",
        "decisions",
        "metrics"
    )) {
        $Path = Join-Path $Base ($Folder + "\" + $KnowledgeId + ".json")
        $Record = Read-AIOfficeDepartmentJson -Path $Path

        if ($null -ne $Record) {
            return $Record
        }
    }

    throw "Department knowledge item not found: $KnowledgeId"
}
