param(
    [switch]$Persist
)

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$Prompts = @(
    [pscustomobject]@{
        name = "conversation"
        content = "Hello! Give me a friendly one-sentence greeting."
        expected_family = "conversation"
        expected_model = "qwen2.5-coder:3b"
    },
    [pscustomobject]@{
        name = "reasoning"
        content = "Reason through why doubling both numbers in a ratio leaves the ratio unchanged."
        expected_family = "reasoning"
        expected_model = "deepseek-r1:1.5b"
    },
    [pscustomobject]@{
        name = "creative"
        content = "Write a short silly poem about a cat driving a Kia."
        expected_family = "creative"
        expected_model = "qwen2.5-coder:3b"
    },
    [pscustomobject]@{
        name = "drafting"
        content = "Draft a concise professional follow-up email asking a vendor for an overdue pricing explanation."
        expected_family = "drafting"
        expected_model = "qwen2.5:3b"
    },
    [pscustomobject]@{
        name = "coding"
        content = "Debug this PowerShell variable parser issue involving a colon after a variable name."
        expected_family = "coding"
        expected_model = "qwen2.5-coder:3b"
    }
)

$Session = & ".\scripts\conversational-office\New-AIOfficeConversationSession.ps1" `
    -Title "v2.5 Live Intelligence Validation"

$Results = New-Object System.Collections.Generic.List[object]

foreach ($Prompt in $Prompts) {
    Write-Host ("Validating " + $Prompt.name + "...") -ForegroundColor Cyan

    $Result = & ".\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" `
        -SessionId ([string]$Session.session_id) `
        -Content ([string]$Prompt.content) `
        -Sensitivity "normal"

    $Passed = (
        [string]$Result.task_family -eq [string]$Prompt.expected_family -and
        [string]$Result.model -eq [string]$Prompt.expected_model -and
        -not [string]::IsNullOrWhiteSpace([string]$Result.response)
    )

    $Results.Add([pscustomobject]@{
        name = [string]$Prompt.name
        task_family = [string]$Result.task_family
        model = [string]$Result.model
        expected_family = [string]$Prompt.expected_family
        expected_model = [string]$Prompt.expected_model
        fallback_used = [bool]$Result.intelligence_fallback_used
        requires_escalation = [bool]$Result.requires_escalation
        passed = $Passed
        response = [string]$Result.response
    })

    $Color = if ($Passed) { "Green" } else { "Red" }

    Write-Host (
        "  model=" + [string]$Result.model +
        " | family=" + [string]$Result.task_family +
        " | fallback=" + [string]$Result.intelligence_fallback_used +
        " | escalation=" + [string]$Result.requires_escalation
    ) -ForegroundColor $Color
}

$PassedCount = @($Results | Where-Object { $_.passed }).Count
$FailedCount = @($Results | Where-Object { -not $_.passed }).Count

$Summary = [ordered]@{
    validation_id = "INTLIVE-" + (Get-Date -Format "yyyyMMdd-HHmmss") + "-" + ([guid]::NewGuid().ToString("N").Substring(0,6)).ToUpperInvariant()
    session_id = [string]$Session.session_id
    passed = $PassedCount
    failed = $FailedCount
    results = $Results.ToArray()
    created_at = (Get-Date).ToString("o")
}

if ($Persist) {
    $Directory = "E:\AI\AI-Office\workspace\intelligence\live-validations"
    New-Item -ItemType Directory -Path $Directory -Force | Out-Null

    $Summary |
        ConvertTo-Json -Depth 100 |
        Set-Content `
            -LiteralPath (Join-Path $Directory ($Summary.validation_id + ".json")) `
            -Encoding UTF8
}

return [pscustomobject]$Summary
