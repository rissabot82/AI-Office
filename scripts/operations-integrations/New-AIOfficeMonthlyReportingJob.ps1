param(
    [string]$Schedule = "monthly"
)

$ErrorActionPreference = "Stop"

$Existing = @(
    Get-ChildItem `
        -LiteralPath "E:\AI\AI-Office\workspace\operations-integrations\jobs" `
        -Filter "OPSJOB-*.json" `
        -File `
        -ErrorAction SilentlyContinue |
    ForEach-Object {
        try {
            Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json
        }
        catch {
        }
    } |
    Where-Object {
        $null -ne $_ -and
        [string]$_.handler -eq "monthly-reporting"
    }
)

if ($Existing.Count -gt 0) {
    Write-Host "Monthly Reporting job already exists: $($Existing[0].job_id)" -ForegroundColor Yellow
    return $Existing[0]
}

return & "E:\AI\AI-Office\scripts\operations-integrations\New-AIOfficeOperationalJob.ps1" `
    -Name "Monthly Reporting" `
    -JobType "reporting" `
    -Schedule $Schedule `
    -Handler "monthly-reporting" `
    -Department "monthly-reporting" `
    -MetadataJson '{"workflow_version":"1.9","review_required":true}'
