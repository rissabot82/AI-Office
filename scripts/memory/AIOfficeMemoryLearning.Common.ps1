. (Join-Path $PSScriptRoot "AIOfficeMemoryRecall.Common.ps1")

function Get-AIOfficeMemoryLearningPolicy {
    $Root = Get-AIOfficeMemoryRoot

    return Read-AIOfficeMemoryJson `
        -Path (Join-Path $Root "config\memory\memory-learning-health-policy.json")
}

function New-AIOfficeMemoryFeedbackId {
    return (
        "MFB-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}

function New-AIOfficeMemoryConflictId {
    return (
        "MCF-" +
        (Get-Date).ToString("yyyyMMdd-HHmmss") +
        "-" +
        ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    )
}
