$script:AIOfficeVenturePlanningRoot = "E:\AI\AI-Office"

function Get-AIOfficeVenturePlanningPolicy {
    return Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\business-incubator\venture-planning-policy.json" `
        -Raw |
        ConvertFrom-Json
}

function New-AIOfficeVenturePlanningId {
    param([Parameter(Mandatory=$true)][string]$Prefix)

    return (
        $Prefix + "-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function Get-AIOfficeBusinessIdeaById {
    param([Parameter(Mandatory=$true)][string]$IdeaId)

    . "E:\AI\AI-Office\scripts\business-incubator\AIOfficeBusinessIncubator.Common.ps1"

    $Path = "E:\AI\AI-Office\workspace\business-incubator\ideas\$IdeaId.json"
    $Idea = Read-AIOfficeBusinessJson -Path $Path

    if ($null -eq $Idea) {
        throw "Business idea not found: $IdeaId"
    }

    return $Idea
}
