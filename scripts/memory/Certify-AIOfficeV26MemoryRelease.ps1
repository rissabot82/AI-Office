param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "AI OFFICE v2.6 MEMORY & CONTEXT CERTIFICATION" -ForegroundColor Cyan
Write-Host "============================================"
Write-Host ""

$Checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param([string]$Name,[bool]$Passed,[string]$Details)
    $Checks.Add([pscustomobject]@{
        name = $Name
        passed = $Passed
        details = $Details
    })
}

try {
    $Required = @(
        ".\config\memory\memory-policy.json",
        ".\config\memory\memory-write-policy.json",
        ".\config\memory\retrieval-policy.json",
        ".\config\memory\context-assembly-policy.json",
        ".\config\memory\live-integration-policy.json",
        ".\config\memory\operations-policy.json",
        ".\config\memory\capture-policy.json",
        ".\scripts\memory\Save-AIOfficeMemoryRecord.ps1",
        ".\scripts\memory\Search-AIOfficeMemory.ps1",
        ".\scripts\memory\New-AIOfficeMemoryContextPackage.ps1",
        ".\scripts\memory\Get-AIOfficeConversationMemoryContext.ps1",
        ".\scripts\memory\Get-AIOfficeMemoryOperations.ps1",
        ".\scripts\memory\Save-AIOfficeExplicitConversationMemory.ps1",
        ".\scripts\memory\Invoke-AIOfficeExplicitMemoryCaptureForTurn.ps1"
    )

    foreach ($Path in $Required) {
        if (-not (Test-Path -LiteralPath $Path)) {
            throw "Missing required v2.6 artifact: $Path"
        }
    }

    Add-Check "v2.6 Memory Artifacts" $true "All A-G memory components are present."
}
catch {
    Add-Check "v2.6 Memory Artifacts" $false $_.Exception.Message
}

try {
    $Runtime = Get-Content ".\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" -Raw

    foreach ($Marker in @(
        "Get-AIOfficeConversationMemoryContext.ps1",
        "Add-AIOfficeMemoryContextToPrompt.ps1",
        "Invoke-AIOfficeExplicitMemoryCaptureForTurn.ps1",
        "Invoke-AIOfficeQualityControlledInference.ps1",
        "fallback_to_memory_free_runtime_on_failure"
    )) {
        if (-not $Runtime.Contains($Marker)) {
            throw "Runtime missing final integration marker: $Marker"
        }
    }

    Add-Check "Live Runtime Wiring" $true "Retrieval, bounded context, explicit capture, quality control, and fallback are wired."
}
catch {
    Add-Check "Live Runtime Wiring" $false $_.Exception.Message
}

try {
    $Token = "hcert" + [guid]::NewGuid().ToString("N").Substring(0,10)

    $Capture = & ".\scripts\memory\Invoke-AIOfficeExplicitMemoryCaptureForTurn.ps1" `
        -Content ("Remember that " + $Token + " is the v2.6 final certification token.") `
        -Scope "CERT-MEMORY-H"

    if (-not [bool]$Capture.captured) {
        throw "Explicit live capture helper did not create memory."
    }

    $Search = @(
        & ".\scripts\memory\Search-AIOfficeMemory.ps1" `
            -Query $Token `
            -Scope "CERT-MEMORY-H" `
            -MaxItems 5
    )

    if ($Search.Count -lt 1) {
        throw "Captured final-certification memory could not be retrieved."
    }

    & ".\scripts\memory\Disable-AIOfficeMemoryRecord.ps1" `
        -MemoryId ([string]$Capture.memory_id)

    Add-Check "Explicit Capture End-to-End" $true "Explicit memory capture and retrieval passed."
}
catch {
    Add-Check "Explicit Capture End-to-End" $false $_.Exception.Message
}

try {
    $Token = "contextfinal" + [guid]::NewGuid().ToString("N").Substring(0,10)

    $Memory = & ".\scripts\memory\Save-AIOfficeMemoryRecord.ps1" `
        -MemoryType "project" `
        -Title "v2.6 Final Context Fixture" `
        -Content ($Token + " bounded context certification memory") `
        -Source "certification" `
        -Scope "CERT-MEMORY-H-CONTEXT" `
        -AllowDuplicate

    $Context = & ".\scripts\memory\Get-AIOfficeConversationMemoryContext.ps1" `
        -Content $Token `
        -Scope "CERT-MEMORY-H-CONTEXT"

    if (-not [bool]$Context.used) {
        throw "Live context retrieval did not select the certification memory."
    }

    if (-not ([string]$Context.context_text).Contains($Token)) {
        throw "Bounded context does not contain expected certification token."
    }

    & ".\scripts\memory\Disable-AIOfficeMemoryRecord.ps1" `
        -MemoryId ([string]$Memory.memory_id)

    Add-Check "Live Context End-to-End" $true "Retrieval and bounded context assembly passed."
}
catch {
    Add-Check "Live Context End-to-End" $false $_.Exception.Message
}

try {
    $Ops = & ".\scripts\memory\Get-AIOfficeMemoryOperations.ps1"

    if ([int]$Ops.enabled_records -lt 0 -or [int]$Ops.total_records -lt 0) {
        throw "Invalid memory operations counts."
    }

    Add-Check "Memory Operations" $true (
        "records=" + [string]$Ops.total_records +
        "; enabled=" + [string]$Ops.enabled_records +
        "; snapshots=" + [string]$Ops.context_snapshots
    )
}
catch {
    Add-Check "Memory Operations" $false $_.Exception.Message
}

try {
    $Quality = Get-Content ".\scripts\intelligence\Invoke-AIOfficeQualityControlledInference.ps1" -Raw
    $DiscordRuntime = Get-Content ".\scripts\discord-office\AIOfficeDiscordRuntime.Common.ps1" -Raw
    $Worker = Get-Content ".\scripts\discord-office\Invoke-AIOfficeDiscordWorker.ps1" -Raw

    foreach ($Marker in @("output_sanitized","FirstLeakIndex")) {
        if (-not $Quality.Contains($Marker)) {
            throw "Missing v2.5.1 response-safety marker: $Marker"
        }
    }

    if (-not $DiscordRuntime.Contains("[System.Text.Encoding]::UTF8.GetBytes")) {
        throw "Discord UTF-8 transport hotfix missing."
    }

    if (-not $Worker.Contains("failed-messages")) {
        throw "Discord poison-message protection missing."
    }

    Add-Check "v2.5.1 Reliability Protections" $true "Output sanitizer, UTF-8 transport, and poison-message protection preserved."
}
catch {
    Add-Check "v2.5.1 Reliability Protections" $false $_.Exception.Message
}

try {
    $Ops = & ".\scripts\discord-office\Get-AIOfficeDiscordOperationsStatus.ps1"

    if (-not [bool]$Ops.discord_connected) {
        throw "Discord is not connected."
    }

    if ([string]$Ops.worker_status -ne "running") {
        throw "Discord worker is not running."
    }

    if ([string]$Ops.self_hosting_status -ne "healthy") {
        throw "Self-hosting is not healthy."
    }

    Add-Check "Discord Runtime Health" $true (
        "connected=True; worker=running; errors=" + [string]$Ops.worker_errors
    )
}
catch {
    Add-Check "Discord Runtime Health" $false $_.Exception.Message
}

$Passed = @($Checks | Where-Object { $_.passed }).Count
$Failed = @($Checks | Where-Object { -not $_.passed }).Count
$Status = if ($Failed -eq 0) { "passed" } else { "failed" }

foreach ($Check in $Checks) {
    if ($Check.passed) {
        Write-Host ("[PASS] " + $Check.name) -ForegroundColor Green
    }
    else {
        Write-Host ("[FAIL] " + $Check.name) -ForegroundColor Red
    }
}

$Result = [ordered]@{
    certification_id = "CERT-MEMORY-" + (Get-Date -Format "yyyyMMdd-HHmmss")
    version = "2.6.0"
    release_name = "Memory & Context Integration"
    status = $Status
    passed_checks = $Passed
    failed_checks = $Failed
    checks = $Checks.ToArray()
    certified_at = (Get-Date).ToString("o")
}

$Directory = ".\workspace\memory\certifications"
New-Item -ItemType Directory -Path $Directory -Force | Out-Null

$CertPath = Join-Path $Directory ($Result.certification_id + ".json")
$Result | ConvertTo-Json -Depth 50 | Set-Content $CertPath -Encoding UTF8

Write-Host ""
if ($Failed -eq 0) {
    Write-Host ("Status: passed | Passed=" + $Passed + " | Failed=0") -ForegroundColor Green
}
else {
    Write-Host ("Status: failed | Passed=" + $Passed + " | Failed=" + $Failed) -ForegroundColor Red
}
Write-Host ("Certification: " + $CertPath) -ForegroundColor Cyan

return [pscustomobject]$Result
