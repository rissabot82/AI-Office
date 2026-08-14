param()

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.6 Part B Durable Memory Records & Indexing..." -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

foreach ($Json in @(
    ".\config\memory\memory-write-policy.json",
    ".\workspace\memory\indexes\memory-index.json"
)) {
    try {
        Get-Content $Json -Raw | ConvertFrom-Json | Out-Null
        Write-Host "[VALID JSON] $Json" -ForegroundColor Green
    }
    catch {
        $Errors.Add("Invalid JSON: $Json")
    }
}

foreach ($Script in @(
    ".\scripts\memory\New-AIOfficeMemoryId.ps1",
    ".\scripts\memory\Save-AIOfficeMemoryRecord.ps1",
    ".\scripts\memory\Get-AIOfficeMemoryRecord.ps1",
    ".\scripts\memory\Get-AIOfficeMemoryIndex.ps1",
    ".\scripts\memory\Disable-AIOfficeMemoryRecord.ps1",
    ".\scripts\memory\Test-AIOfficeDurableMemoryRecords.ps1"
)) {
    if (Test-Path -LiteralPath $Script) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        $Errors.Add("Missing script: $Script")
    }
}

$TestId = $null

try {
    $Created = & ".\scripts\memory\Save-AIOfficeMemoryRecord.ps1" `
        -MemoryType "project" `
        -Title "v2.6 Part B Certification Memory" `
        -Content "Temporary certification memory for durable-record validation." `
        -Source "certification" `
        -Scope "AI-Office" `
        -Tags @("certification","temporary")

    if (-not [bool]$Created.created) {
        throw "Certification record was not created."
    }

    $TestId = [string]$Created.memory_id
    Write-Host "[WRITE OK] $TestId" -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

if ($TestId) {
    try {
        $Record = & ".\scripts\memory\Get-AIOfficeMemoryRecord.ps1" -MemoryId $TestId

        if ([string]$Record.content -ne "Temporary certification memory for durable-record validation.") {
            throw "Retrieved memory content mismatch."
        }

        Write-Host "[READ OK] Durable record retrieved." -ForegroundColor Green
    }
    catch {
        $Errors.Add($_.Exception.Message)
    }

    try {
        $Matches = @(
            & ".\scripts\memory\Get-AIOfficeMemoryIndex.ps1" `
                -MemoryType "project" `
                -Scope "AI-Office"
        )

        if (@($Matches | Where-Object { [string]$_.memory_id -eq $TestId }).Count -ne 1) {
            throw "Index lookup did not return certification record."
        }

        Write-Host "[INDEX OK] Type/scope lookup returned certification record." -ForegroundColor Green
    }
    catch {
        $Errors.Add($_.Exception.Message)
    }

    try {
        & ".\scripts\memory\Disable-AIOfficeMemoryRecord.ps1" -MemoryId $TestId

        $EnabledMatches = @(
            & ".\scripts\memory\Get-AIOfficeMemoryIndex.ps1" `
                -MemoryType "project" `
                -Scope "AI-Office"
        )

        if (@($EnabledMatches | Where-Object { [string]$_.memory_id -eq $TestId }).Count -ne 0) {
            throw "Disabled memory still appears in default index results."
        }

        Write-Host "[DISABLE OK] Disabled record excluded from normal results." -ForegroundColor Green
    }
    catch {
        $Errors.Add($_.Exception.Message)
    }
}

try {
    $SecretBlocked = $false

    try {
        & ".\scripts\memory\Save-AIOfficeMemoryRecord.ps1" `
            -MemoryType "project" `
            -Title "Secret Test" `
            -Content "api_key = should-never-be-stored" `
            -Source "certification" `
            -Scope "AI-Office" | Out-Null
    }
    catch {
        $SecretBlocked = $true
    }

    if (-not $SecretBlocked) {
        throw "Secret-like memory content was not blocked."
    }

    Write-Host "[SECRET SAFETY OK] Secret-like memory rejected." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

try {
    $Runtime = Get-Content ".\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" -Raw

    if (-not $Runtime.Contains("Invoke-AIOfficeQualityControlledInference.ps1")) {
        throw "v2.5.1 live runtime marker missing."
    }

    Write-Host "[PRODUCTION SAFETY OK] Live runtime remains unchanged." -ForegroundColor Green
}
catch {
    $Errors.Add($_.Exception.Message)
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    foreach ($Item in $Errors) {
        Write-Host "[MEMORY ERR] $Item" -ForegroundColor Red
    }

    throw "$($Errors.Count) Durable Memory Records & Indexing error(s) found."
}

Write-Host ""
Write-Host "All AI Office v2.6 Part B Durable Memory Records & Indexing checks passed." -ForegroundColor Green
