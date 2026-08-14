param()

$ErrorActionPreference = "Stop"

$Path = "E:\AI\AI-Office\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1"
$Content = Get-Content -LiteralPath $Path -Raw

$Old = @'
            $Execution = & "E:\AI\AI-Office\scripts\intelligence\Invoke-AIOfficeSelectedLocalInference.ps1" `
                -Model ([string]$IntelligentSelection.selected_model) `
                -Prompt $Prompt
'@

$New = @'
            $Execution = & "E:\AI\AI-Office\scripts\intelligence\Invoke-AIOfficeQualityControlledInference.ps1" `
                -Model ([string]$IntelligentSelection.selected_model) `
                -Prompt $Prompt `
                -TaskFamily ([string]$IntelligentSelection.task_family)
'@

if ($Content.Contains("Invoke-AIOfficeQualityControlledInference.ps1")) {
    Write-Host "[ALREADY ENABLED] Response quality control is already wired into the live runtime." -ForegroundColor Yellow
    return
}

if (-not $Content.Contains($Old)) {
    throw "Expected Part E selected-inference block was not found. Live runtime was not modified."
}

$Content = $Content.Replace($Old, $New)

Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8

Write-Host "[ENABLED] Response quality control wired into live conversational runtime." -ForegroundColor Green
