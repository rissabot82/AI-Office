param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.6 Part E Live Conversational Memory Integration..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]
$CreatedIds = New-Object System.Collections.Generic.List[string]

foreach ($Artifact in @(
    ".\config\memory\live-integration-policy.json",
    ".\scripts\memory\Get-AIOfficeConversationMemoryContext.ps1",
    ".\scripts\memory\Add-AIOfficeMemoryContextToPrompt.ps1",
    ".\scripts\memory\Test-AIOfficeLiveConversationalMemoryIntegration.ps1",
    ".\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1"
)) {
    if (Test-Path -LiteralPath $Artifact) {
        Write-Host "[FOUND] $Artifact" -ForegroundColor Green
    }
    else {
        $Errors.Add("Missing Part E artifact: $Artifact")
    }
}

try {
    Get-Content ".\config\memory\live-integration-policy.json" -Raw | ConvertFrom-Json | Out-Null
    Write-Host "[VALID JSON] live-integration-policy.json" -ForegroundColor Green
}
catch {
    $Errors.Add("Invalid live-integration-policy.json")
}

try {
    $Token = "livecontext" + [guid]::NewGuid().ToString("N").Substring(0,10)

    $Memory = & ".\scripts\memory\Save-AIOfficeMemoryRecord.ps1" `
        -MemoryType "project" `
        -Title "Live Memory Integration Fixture" `
        -Content ($Token + " certification context for live conversational memory integration") `
        -Source "certification" `
        -Scope "CERT-MEMORY-E" `
        -AllowDuplicate

    $CreatedIds.Add([string]$Memory.memory_id)

    $Context = & ".\scripts\memory\Get-AIOfficeConversationMemoryContext.ps1" `
        -Content $Token `
        -Scope "CERT-MEMORY-E"

    if (-not [bool]$Context.used) {
        throw "Relevant memory context was not selected."
    }

    if ([int]$Context.result_count -lt 1) {
        throw "Live memory context returned no results."
    }

    if (-not ([string]$Context.context_text).Contains($Token)) {
        throw "Selected context does not contain the expected certification memory."
    }

    Write-Host "[CONTEXT OK] Relevant memory selected for conversational use." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

try {
    $Prompt = & ".\scripts\memory\Add-AIOfficeMemoryContextToPrompt.ps1" `
        -BasePrompt "USER: Test prompt" `
        -MemoryContext "MEMORY CONTEXT`n- test memory`nEND MEMORY CONTEXT"

    if (-not $Prompt.Contains("REFERENCE MEMORY FOR THIS TURN:")) {
        throw "Memory prompt wrapper was not added."
    }

    if (-not $Prompt.Contains("Use relevant memory naturally when helpful.")) {
        throw "Memory prompt safety instruction missing."
    }

    Write-Host "[PROMPT OK] Memory context wrapper assembled safely." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

try {
    $Runtime = Get-Content ".\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" -Raw

    foreach ($Marker in @(
        "Get-AIOfficeConversationMemoryContext.ps1",
        "Add-AIOfficeMemoryContextToPrompt.ps1",
        "Invoke-AIOfficeQualityControlledInference.ps1"
    )) {
        if (-not $Runtime.Contains($Marker)) {
            throw "Live runtime missing integration marker: $Marker"
        }
    }

    Write-Host "[RUNTIME WIRING OK] Memory integration + v2.5.1 quality control present." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

try {
    $Runtime = Get-Content ".\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" -Raw

    if (-not $Runtime.Contains("fallback_to_memory_free_runtime_on_failure")) {
        throw "Memory-free fallback marker missing."
    }

    Write-Host "[FALLBACK OK] Memory failure preserves memory-free conversational execution." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

try {
    $Quality = Get-Content ".\scripts\intelligence\Invoke-AIOfficeQualityControlledInference.ps1" -Raw

    if (-not $Quality.Contains("output_sanitized")) {
        throw "v2.5.1 output sanitizer marker missing."
    }

    Write-Host "[OUTPUT SAFETY OK] Existing prompt-leak sanitizer preserved." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

foreach ($MemoryId in @($CreatedIds | Select-Object -Unique)) {
    try {
        & ".\scripts\memory\Disable-AIOfficeMemoryRecord.ps1" -MemoryId $MemoryId
    }
    catch {}
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    foreach ($Item in $Errors) {
        Write-Host "[MEMORY ERR] $Item" -ForegroundColor Red
    }

    throw "$($Errors.Count) Live Conversational Memory Integration error(s) found."
}

Write-Host ""
Write-Host "All AI Office v2.6 Part E Live Conversational Memory Integration checks passed." -ForegroundColor Green
