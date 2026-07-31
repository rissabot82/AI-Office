param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.3 Part B Memory Capture, Search, and Recall..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\memory\memory-capture-recall-policy.json",
    ".\config\memory\memory-context-packet-schema.json",
    ".\config\memory\memory-capture-record-schema.json",
    ".\workspace\templates\memory-context-packet-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw |
            ConvertFrom-Json |
            Out-Null

        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: " + $File)
    }
}

$Scripts = @(
    ".\scripts\memory\AIOfficeMemoryRecall.Common.ps1",
    ".\scripts\memory\New-AIOfficeMemory.ps1",
    ".\scripts\memory\Search-AIOfficeMemory.ps1",
    ".\scripts\memory\Get-AIOfficeMemory.ps1",
    ".\scripts\memory\Find-AIOfficeMemoryDuplicates.ps1",
    ".\scripts\memory\Find-AIOfficeRelatedMemory.ps1",
    ".\scripts\memory\New-AIOfficeMemoryContextPacket.ps1",
    ".\scripts\memory\Import-AIOfficeMemoryFromJson.ps1",
    ".\scripts\memory\Test-AIOfficeMemoryCaptureRecall.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING    ] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: " + $Script)
    }
}

$MemoryIds = New-Object System.Collections.Generic.List[string]
$PacketId = ""

try {
    $MemoryOne = & ".\scripts\memory\New-AIOfficeMemory.ps1" `
        -Scope "department" `
        -Department "marketing" `
        -MemoryType "lesson" `
        -Title "Campaign structure validation" `
        -Summary "Reusable dealership campaign workflow." `
        -ContentJson '{"steps":["offer","creative","website","tracking"],"result":"successful"}' `
        -SourceJson '{"type":"validation","source_id":"MEMORY-PART-B"}' `
        -Confidence 0.90 `
        -Tags @("campaign","dealership") `
        -Entities @("Elite Auto Sales") `
        -Projects @("Memory Validation")

    $MemoryTwo = & ".\scripts\memory\New-AIOfficeMemory.ps1" `
        -Scope "business" `
        -MemoryType "decision" `
        -Title "Campaign structure decision" `
        -Summary "Use a repeatable campaign launch sequence." `
        -ContentJson '{"decision":"Use offer, creative, page, tracking, reporting sequence."}' `
        -SourceJson '{"type":"validation","source_id":"MEMORY-PART-B-2"}' `
        -Confidence 0.85 `
        -Tags @("campaign","workflow") `
        -Entities @("Elite Auto Sales") `
        -Projects @("Memory Validation")

    $MemoryIds.Add([string]$MemoryOne.memory_id)
    $MemoryIds.Add([string]$MemoryTwo.memory_id)

    Write-Host "[CREATE OK  ] 2 memory records" -ForegroundColor Green
}
catch {
    Write-Host "[CREATE ERR ] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Memory creation failed: " + $_.Exception.Message)
}

try {
    $Search = @(
        & ".\scripts\memory\Search-AIOfficeMemory.ps1" `
            -Query "campaign" `
            -MinimumConfidence 0.50 `
            -Limit 10
    )

    if ($Search.Count -lt 2) {
        throw "Memory search returned fewer than two results."
    }

    Write-Host (
        "[SEARCH OK  ] " +
        $Search.Count.ToString() +
        " result(s)"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[SEARCH ERR ] $($_.Exception.Message)" -ForegroundColor Red
    $Errors.Add("Memory search failed: " + $_.Exception.Message)
}

try {
    $Duplicate = & ".\scripts\memory\Find-AIOfficeMemoryDuplicates.ps1" `
        -Title "Campaign structure validation" `
        -Summary "Reusable dealership campaign workflow." `
        -Scope "department" `
        -Department "marketing"

    if ([int]$Duplicate.duplicate_count -lt 1) {
        throw "Duplicate detection found no matches."
    }

    Write-Host "[DUPLICATE OK] Duplicate detection passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[DUPLICATE ER] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Duplicate detection failed: " + $_.Exception.Message)
}

try {
    $Related = & ".\scripts\memory\Find-AIOfficeRelatedMemory.ps1" `
        -MemoryId ([string]$MemoryIds[0]) `
        -Limit 10

    if ([int]$Related.related_count -lt 1) {
        throw "Related-memory discovery found no matches."
    }

    Write-Host "[RELATED OK ] Related-memory discovery passed." `
        -ForegroundColor Green
}
catch {
    Write-Host "[RELATED ERR] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Related-memory discovery failed: " + $_.Exception.Message)
}

try {
    $Packet = & ".\scripts\memory\New-AIOfficeMemoryContextPacket.ps1" `
        -Query "campaign" `
        -RequestedBy "chief-of-staff" `
        -Limit 10

    $PacketId = [string]$Packet.context_packet_id

    if ([int]$Packet.memory_count -lt 2) {
        throw "Context packet contained fewer than two memories."
    }

    Write-Host (
        "[CONTEXT OK ] " +
        $PacketId +
        " | " +
        [string]$Packet.memory_count +
        " memory record(s)"
    ) -ForegroundColor Green
}
catch {
    Write-Host "[CONTEXT ERR] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Context packet failed: " + $_.Exception.Message)
}

foreach ($MemoryId in $MemoryIds) {
    $File = $null

    try {
        . ".\scripts\memory\AIOfficeMemoryRecall.Common.ps1"
        $File = Find-AIOfficeMemoryFile -MemoryId $MemoryId
    }
    catch {
    }

    if ($null -ne $File -and
        (Test-Path -LiteralPath $File.FullName -PathType Leaf)) {
        Remove-Item -LiteralPath $File.FullName -Force
    }
}

if ($PacketId) {
    $Path = ".\workspace\memory\context-packets\$PacketId.json"

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

Get-ChildItem `
    -LiteralPath ".\workspace\memory\captures" `
    -Filter "MCAP-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        $Record = Get-Content -LiteralPath $_.FullName -Raw |
            ConvertFrom-Json

        if ($MemoryIds -contains [string]$Record.memory_id) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

& ".\scripts\memory\Update-AIOfficeMemoryIndex.ps1" |
    Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Memory Capture, Search, and Recall error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.3 Part B Memory Capture, Search, and Recall checks passed." `
    -ForegroundColor Green
