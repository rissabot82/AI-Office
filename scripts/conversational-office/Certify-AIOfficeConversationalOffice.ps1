param()

$ErrorActionPreference = "Stop"

$Checks = New-Object System.Collections.Generic.List[object]

function Add-ConversationCertificationCheck {
    param([string]$Name,[bool]$Passed,[string]$Details)

    $Checks.Add([pscustomobject]@{
        name = $Name
        passed = $Passed
        details = $Details
    })
}

function Invoke-ConversationValidation {
    param(
        [string]$Name,
        [string]$ScriptPath,
        [string]$ExpectedText
    )

    try {
        $Output = & powershell.exe `
            -NoProfile `
            -ExecutionPolicy Bypass `
            -File $ScriptPath 2>&1

        $ExitCode = $LASTEXITCODE
        $Text = ($Output | Out-String).Trim()
        $Passed = ($ExitCode -eq 0 -and $Text -like ("*" + $ExpectedText + "*"))

        Add-ConversationCertificationCheck `
            -Name $Name `
            -Passed $Passed `
            -Details $(if ($Passed) { "Validation passed." } else { $Text })
    }
    catch {
        Add-ConversationCertificationCheck `
            -Name $Name `
            -Passed $false `
            -Details $_.Exception.Message
    }
}

Invoke-ConversationValidation `
    -Name "Part A Conversational Intake Architecture" `
    -ScriptPath "E:\AI\AI-Office\scripts\conversational-office\Test-AIOfficeConversationArchitecture.ps1" `
    -ExpectedText "All AI Office v2.3 Part A Conversational Intake Architecture checks passed."

Invoke-ConversationValidation `
    -Name "Part B Live Conversational Runtime" `
    -ScriptPath "E:\AI\AI-Office\scripts\conversational-office\Test-AIOfficeConversationRuntime.ps1" `
    -ExpectedText "All AI Office v2.3 Part B Live Conversational Runtime checks passed."

try {
    & "E:\AI\AI-Office\scripts\conversational-office\Test-AIOfficeConversationDashboard.ps1" | Out-Null
    Add-ConversationCertificationCheck `
        -Name "Part C Conversational Dashboard" `
        -Passed $true `
        -Details "Dashboard validation passed."
}
catch {
    Add-ConversationCertificationCheck `
        -Name "Part C Conversational Dashboard" `
        -Passed $false `
        -Details $_.Exception.Message
}

try {
    $Manifest = Get-Content `
        -LiteralPath "E:\AI\AI-Office\config\conversational-office\release-manifest.json" `
        -Raw |
        ConvertFrom-Json

    $Passed = (
        [string]$Manifest.version -eq "2.3.0" -and
        [string]$Manifest.status -eq "release_candidate"
    )

    Add-ConversationCertificationCheck `
        -Name "Release Manifest" `
        -Passed $Passed `
        -Details ("version=" + [string]$Manifest.version + "; status=" + [string]$Manifest.status)
}
catch {
    Add-ConversationCertificationCheck `
        -Name "Release Manifest" `
        -Passed $false `
        -Details $_.Exception.Message
}

$PassedCount = @($Checks | Where-Object { $_.passed -eq $true }).Count
$FailedCount = @($Checks | Where-Object { $_.passed -ne $true }).Count
$Status = if ($FailedCount -eq 0) { "certified" } else { "failed" }

$Certification = [pscustomobject]@{
    certification_id = "CERT-CONV-" + (Get-Date).ToString("yyyyMMdd-HHmmss")
    version = "2.3.0"
    release_name = "Conversational AI Office"
    certified_at = (Get-Date).ToString("o")
    status = $Status
    passed_checks = $PassedCount
    failed_checks = $FailedCount
    checks = @($Checks | ForEach-Object { $_ })
}

$Directory = "E:\AI\AI-Office\workspace\conversational-office\certifications"
New-Item -ItemType Directory -Path $Directory -Force | Out-Null

$Certification |
    ConvertTo-Json -Depth 100 |
    Set-Content `
        -LiteralPath (Join-Path $Directory ($Certification.certification_id + ".json")) `
        -Encoding UTF8

Write-Host ""
Write-Host "Conversational AI Office certification: $Status | $PassedCount passed, $FailedCount failed" `
    -ForegroundColor $(if ($Status -eq "certified") { "Green" } else { "Red" })

return $Certification
