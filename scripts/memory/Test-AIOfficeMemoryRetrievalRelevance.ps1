param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.6 Part C Memory Retrieval & Relevance..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]
$CreatedIds = New-Object System.Collections.Generic.List[string]

foreach ($Artifact in @(
    ".\config\memory\retrieval-policy.json",
    ".\scripts\memory\Get-AIOfficeMemorySearchTokens.ps1",
    ".\scripts\memory\Get-AIOfficeMemoryRelevanceScore.ps1",
    ".\scripts\memory\Search-AIOfficeMemory.ps1",
    ".\scripts\memory\Show-AIOfficeMemorySearch.ps1",
    ".\scripts\memory\Test-AIOfficeMemoryRetrievalRelevance.ps1"
)) {
    if (Test-Path -LiteralPath $Artifact) {
        Write-Host "[FOUND] $Artifact" -ForegroundColor Green
    }
    else {
        $Errors.Add("Missing Part C artifact: $Artifact")
    }
}

try {
    Get-Content `
        ".\config\memory\retrieval-policy.json" `
        -Raw |
        ConvertFrom-Json |
        Out-Null

    Write-Host "[VALID JSON] retrieval-policy.json" -ForegroundColor Green
}
catch {
    $Errors.Add("Invalid retrieval-policy.json")
}


# ------------------------------------------------------------
# RANKING TEST
# ------------------------------------------------------------

try {
    $RunToken = [guid]::NewGuid().ToString("N").Substring(0,10)

    $EliteToken = "elitecert" + $RunToken
    $KiaToken = "kiacert" + $RunToken

    $Elite = & ".\scripts\memory\Save-AIOfficeMemoryRecord.ps1" `
        -MemoryType "dealership" `
        -Title "Elite Auto Sales Wichita" `
        -Content ($EliteToken + " Elite Auto Sales Wichita dealership automotive marketing") `
        -Source "certification" `
        -Scope "CERT-MEMORY-C" `
        -Tags @("elite","wichita","dealership") `
        -AllowDuplicate

    $Kia = & ".\scripts\memory\Save-AIOfficeMemoryRecord.ps1" `
        -MemoryType "dealership" `
        -Title "Kia of Manhattan" `
        -Content ($KiaToken + " Kia of Manhattan dealership Kia marketing") `
        -Source "certification" `
        -Scope "CERT-MEMORY-C" `
        -Tags @("kia","manhattan","dealership") `
        -AllowDuplicate

    if (-not [bool]$Elite.created) {
        throw "Fresh Elite certification fixture was not created."
    }

    if (-not [bool]$Kia.created) {
        throw "Fresh Kia certification fixture was not created."
    }

    $CreatedIds.Add([string]$Elite.memory_id)
    $CreatedIds.Add([string]$Kia.memory_id)

    Write-Host "[FIXTURES OK] Fresh certification memories created." -ForegroundColor Green

    $RankingResults = @(
        & ".\scripts\memory\Search-AIOfficeMemory.ps1" `
            -Query ($EliteToken + " Wichita dealership") `
            -Scope "CERT-MEMORY-C" `
            -MemoryTypes @("dealership") `
            -MaxItems 5
    )

    if ($RankingResults.Count -lt 1) {
        throw "Retrieval returned no results."
    }

    if ([string]$RankingResults[0].memory_id -ne [string]$Elite.memory_id) {
        throw "Expected Elite Auto Sales certification memory to rank first."
    }

    Write-Host "[RANKING OK] Relevant dealership ranked first." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}


# ------------------------------------------------------------
# SCOPE ISOLATION TEST
# ------------------------------------------------------------

try {
    $ScopeToken = "scopecert" + [guid]::NewGuid().ToString("N").Substring(0,10)

    $ScopeFixture = & ".\scripts\memory\Save-AIOfficeMemoryRecord.ps1" `
        -MemoryType "project" `
        -Title "Scope Isolation Fixture" `
        -Content ($ScopeToken + " scope isolation fixture") `
        -Source "certification" `
        -Scope "CERT-MEMORY-C" `
        -AllowDuplicate

    $CreatedIds.Add([string]$ScopeFixture.memory_id)

    $CrossScope = @(
        & ".\scripts\memory\Search-AIOfficeMemory.ps1" `
            -Query $ScopeToken `
            -Scope "OTHER-SCOPE" `
            -MaxItems 5
    )

    if ($CrossScope.Count -ne 0) {
        throw "Cross-scope retrieval returned records while cross-project retrieval is disabled."
    }

    Write-Host "[SCOPE SAFETY OK] Cross-scope retrieval blocked." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}


# ------------------------------------------------------------
# DISABLED MEMORY TEST
# ------------------------------------------------------------

try {
    $DisabledToken = "disabledcert" + [guid]::NewGuid().ToString("N").Substring(0,10)

    $Disabled = & ".\scripts\memory\Save-AIOfficeMemoryRecord.ps1" `
        -MemoryType "project" `
        -Title "Disabled Search Fixture" `
        -Content ($DisabledToken + " disabled retrieval fixture") `
        -Source "certification" `
        -Scope "CERT-MEMORY-C" `
        -AllowDuplicate

    if (-not [bool]$Disabled.created) {
        throw "Fresh disabled-memory fixture was not created."
    }

    $CreatedIds.Add([string]$Disabled.memory_id)

    & ".\scripts\memory\Disable-AIOfficeMemoryRecord.ps1" `
        -MemoryId ([string]$Disabled.memory_id)

    $DisabledResults = @(
        & ".\scripts\memory\Search-AIOfficeMemory.ps1" `
            -Query $DisabledToken `
            -Scope "CERT-MEMORY-C" `
            -MaxItems 5
    )

    $ReturnedIds = @(
        $DisabledResults |
        ForEach-Object {
            [string]$_.memory_id
        }
    )

    if ($ReturnedIds -contains [string]$Disabled.memory_id) {
        throw "Disabled certification memory was returned by search."
    }

    if ($DisabledResults.Count -ne 0) {
        throw "Unique disabled-memory query unexpectedly returned another record."
    }

    Write-Host "[DISABLED FILTER OK] Disabled memory excluded." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}


# ------------------------------------------------------------
# CLEANUP
# ------------------------------------------------------------

foreach ($MemoryId in @($CreatedIds | Select-Object -Unique)) {
    try {
        & ".\scripts\memory\Disable-AIOfficeMemoryRecord.ps1" `
            -MemoryId $MemoryId
    }
    catch {}
}


# ------------------------------------------------------------
# PRODUCTION SAFETY
# ------------------------------------------------------------

try {
    $Runtime = Get-Content `
        ".\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" `
        -Raw

    if ($Runtime.Contains("Search-AIOfficeMemory.ps1")) {
        throw "Part C must not wire memory into live conversations yet."
    }

    Write-Host "[PRODUCTION SAFETY OK] Live conversation runtime remains memory-free." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}


# ------------------------------------------------------------
# FINAL RESULT
# ------------------------------------------------------------

if ($Errors.Count -gt 0) {
    Write-Host ""

    foreach ($Item in $Errors) {
        Write-Host "[MEMORY ERR] $Item" -ForegroundColor Red
    }

    throw "$($Errors.Count) Memory Retrieval & Relevance error(s) found."
}

Write-Host ""
Write-Host "All AI Office v2.6 Part C Memory Retrieval & Relevance checks passed." -ForegroundColor Green
