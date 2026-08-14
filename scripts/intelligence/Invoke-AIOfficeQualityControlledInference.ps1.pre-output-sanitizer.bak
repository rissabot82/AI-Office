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

$Execution | Add-Member -NotePropertyName quality_control_passed -NotePropertyValue $true -Force
$Execution | Add-Member -NotePropertyName quality_retry_used -NotePropertyValue $RetryUsed -Force

return $Execution
