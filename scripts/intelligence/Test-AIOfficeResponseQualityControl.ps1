param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.5 Part G Response Quality Control..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

try {
    Get-Content ".\config\intelligence\response-quality-policy.json" -Raw | ConvertFrom-Json | Out-Null
    Write-Host "[VALID JSON] .\config\intelligence\response-quality-policy.json" -ForegroundColor Green
}
catch {
    $Errors.Add("Invalid response quality policy JSON.")
}

foreach ($Script in @(
    ".\scripts\intelligence\Test-AIOfficeResponseQuality.ps1",
    ".\scripts\intelligence\New-AIOfficeQualityPrompt.ps1",
    ".\scripts\intelligence\Invoke-AIOfficeQualityControlledInference.ps1",
    ".\scripts\intelligence\Enable-AIOfficeResponseQualityControl.ps1",
    ".\scripts\intelligence\Test-AIOfficeResponseQualityControl.ps1"
)) {
    if (Test-Path -LiteralPath $Script) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        $Errors.Add("Missing script: $Script")
    }
}

try {
    $BadResponses = @(
        "ASSISTANT: The Chief Of Staff has noted this request and will coordinate it appropriately for processing by the appropriate department.",
        "I need more information to proceed. Please specify a task.",
        "This request does not belong in the AI Office."
    )

    foreach ($Bad in $BadResponses) {
        $Check = & ".\scripts\intelligence\Test-AIOfficeResponseQuality.ps1" -Response $Bad
        if ([bool]$Check.passed) {
            throw "Known bad response incorrectly passed validation."
        }
    }

    $Good = & ".\scripts\intelligence\Test-AIOfficeResponseQuality.ps1" `
        -Response "A cat in a Kia, paws on the wheel, zoomed past the dog with considerable zeal."

    if (-not [bool]$Good.passed) {
        throw "Known good response failed validation."
    }

    Write-Host "[QUALITY GATE OK] Known bad responses rejected; good response accepted." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
    Write-Host "[QUALITY GATE ERR] $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $Runtime = Get-Content ".\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" -Raw

    if (-not $Runtime.Contains("Invoke-AIOfficeQualityControlledInference.ps1")) {
        throw "Live conversational runtime is not wired to response quality control."
    }

    if (-not $Runtime.Contains("Invoke-AIOfficeOptimizedInference.ps1")) {
        throw "Existing v2.4 fallback is missing."
    }

    Write-Host "[LIVE WIRING OK] Quality-controlled inference + v2.4 fallback present." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
    Write-Host "[LIVE WIRING ERR] $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $Selection = & ".\scripts\intelligence\Select-AIOfficeIntelligentModel.ps1" `
        -Content "Write me a short silly poem about a cat driving a Kia."

    $Prompt = @'
USER: Write me a short silly poem about a cat driving a Kia.

Respond as AI Office Chief of Staff.
'@

    $Execution = & ".\scripts\intelligence\Invoke-AIOfficeQualityControlledInference.ps1" `
        -Model ([string]$Selection.selected_model) `
        -Prompt $Prompt `
        -TaskFamily ([string]$Selection.task_family)

    if (-not [bool]$Execution.quality_control_passed) {
        throw "Live quality-controlled inference did not pass."
    }

    Write-Host "[LIVE QUALITY OK] $($Selection.selected_model) produced a validated creative response." -ForegroundColor Green
    Write-Host ("  " + ([string]$Execution.response -replace "`r|`n"," ")) -ForegroundColor DarkGray
}
catch {
    $Errors.Add($_.Exception.Message)
    Write-Host "[LIVE QUALITY ERR] $($_.Exception.Message)" -ForegroundColor Red
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    foreach ($Item in $Errors) {
        Write-Host "[INTELLIGENCE ERR] $Item" -ForegroundColor Red
    }
    throw "$($Errors.Count) Response Quality Control error(s) found."
}

Write-Host ""
Write-Host "All AI Office v2.5 Part G Response Quality Control checks passed." -ForegroundColor Green
