param(
    [Parameter(Mandatory=$true)][string]$Model,
    [Parameter(Mandatory=$true)][string]$Prompt,
    [Parameter(Mandatory=$true)][string]$TaskFamily
)

$ErrorActionPreference = "Stop"

$Policy = Get-Content `
    -LiteralPath "E:\AI\AI-Office\config\intelligence\response-quality-policy.json" `
    -Raw | ConvertFrom-Json

$QualityPrompt = & "E:\AI\AI-Office\scripts\intelligence\New-AIOfficeQualityPrompt.ps1" `
    -BasePrompt $Prompt `
    -TaskFamily $TaskFamily

$Execution = & "E:\AI\AI-Office\scripts\intelligence\Invoke-AIOfficeSelectedLocalInference.ps1" `
    -Model $Model `
    -Prompt $QualityPrompt

$Quality = & "E:\AI\AI-Office\scripts\intelligence\Test-AIOfficeResponseQuality.ps1" `
    -Response ([string]$Execution.response)

$RetryUsed = $false

if (
    -not [bool]$Quality.passed -and
    [bool]$Policy.quality_control.retry_once_on_quality_failure
) {
    $RetryUsed = $true

    $RetryPrompt = & "E:\AI\AI-Office\scripts\intelligence\New-AIOfficeQualityPrompt.ps1" `
        -BasePrompt $Prompt `
        -TaskFamily $TaskFamily `
        -Retry

    $Execution = & "E:\AI\AI-Office\scripts\intelligence\Invoke-AIOfficeSelectedLocalInference.ps1" `
        -Model $Model `
        -Prompt $RetryPrompt

    $Quality = & "E:\AI\AI-Office\scripts\intelligence\Test-AIOfficeResponseQuality.ps1" `
        -Response ([string]$Execution.response)
}

if (-not [bool]$Quality.passed) {
    throw ("Response quality validation failed: " + (@($Quality.reasons) -join "; "))
}

# Final user-facing output boundary.
# Internal conversation/prompt material must never leave AI Office.
$CleanResponse = [string]$Execution.response

$LeakPatterns = @(
    '(?im)^\s*USER:',
    '(?im)^\s*SYSTEM:',
    '(?im)^\s*ASSISTANT:',
    '(?im)^\s*BEGIN CONVERSATION PROMPT\s*$',
    '(?im)^\s*END CONVERSATION PROMPT\s*$',
    '(?im)^\s*RESPONSE QUALITY RULES:\s*$',
    '(?im)^\s*IMPORTANT RETRY INSTRUCTION:\s*$'
)

$FirstLeakIndex = -1

foreach ($Pattern in $LeakPatterns) {
    $Match = [regex]::Match($CleanResponse, $Pattern)

    if ($Match.Success) {
        if ($FirstLeakIndex -lt 0 -or $Match.Index -lt $FirstLeakIndex) {
            $FirstLeakIndex = $Match.Index
        }
    }
}

if ($FirstLeakIndex -ge 0) {
    $CleanResponse = $CleanResponse.Substring(0,$FirstLeakIndex).Trim()
}

if ([string]::IsNullOrWhiteSpace($CleanResponse)) {
    throw "Response sanitizer removed the entire response because internal prompt material was exposed."
}

$Execution.response = $CleanResponse

$Execution | Add-Member -NotePropertyName quality_control_passed -NotePropertyValue $true -Force
$Execution | Add-Member -NotePropertyName quality_retry_used -NotePropertyValue $RetryUsed -Force
$Execution | Add-Member -NotePropertyName output_sanitized -NotePropertyValue ($FirstLeakIndex -ge 0) -Force

return $Execution

