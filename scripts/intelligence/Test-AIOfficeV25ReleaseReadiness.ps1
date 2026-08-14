param()
$ErrorActionPreference="Stop"
Set-Location "E:\AI\AI-Office"
Write-Host "`nTesting AI Office v2.5 Part L Release Readiness...`n" -ForegroundColor Cyan
$Errors=New-Object System.Collections.Generic.List[string]

foreach($P in @(
 ".\config\intelligence\release-manifest.json",
 ".\docs\AI-Office-v2.5-Release-Notes.md",
 ".\scripts\intelligence\Update-AIOfficeIntelligenceDashboardData.ps1",
 ".\scripts\intelligence\Sync-AIOfficeV25ProjectDocs.ps1",
 ".\scripts\intelligence\Publish-AIOfficeV25Release.ps1"
)){
 if(Test-Path $P){Write-Host "[FOUND] $P" -ForegroundColor Green}else{$Errors.Add("Missing: $P")}
}

try{
 $Latest=Get-ChildItem ".\workspace\intelligence\certifications\CERT-INTELLIGENCE-*.json" -File|Sort-Object LastWriteTime -Descending|Select-Object -First 1
 if(-not $Latest){throw "No final certification found."}
 $C=Get-Content $Latest.FullName -Raw|ConvertFrom-Json
 if([string]$C.status-ne"passed"-or[int]$C.passed_checks-lt14-or[int]$C.failed_checks-ne0){throw "Latest certification is not release-ready."}
 Write-Host "[CERTIFICATION OK] $($C.certification_id) | 14/14" -ForegroundColor Green
}catch{$Errors.Add($_.Exception.Message)}

try{
 & ".\scripts\intelligence\Update-AIOfficeIntelligenceDashboardData.ps1"|Out-Null
 $D=Get-Content ".\dashboard\public\data\intelligence.json" -Raw|ConvertFrom-Json
 if([string]$D.version-ne"2.5.0"){throw "Dashboard version mismatch."}
 Write-Host "[DASHBOARD DATA OK] intelligence.json" -ForegroundColor Green
}catch{$Errors.Add($_.Exception.Message)}

try{
 $Discord=& ".\scripts\discord-office\Get-AIOfficeDiscordOperationsStatus.ps1"
 if(-not[bool]$Discord.discord_connected-or[string]$Discord.worker_status-ne"running"){throw "Discord not operational."}
 Write-Host "[DISCORD OK] connected=True | worker=running" -ForegroundColor Green
}catch{$Errors.Add($_.Exception.Message)}

if($Errors.Count-gt0){$Errors|ForEach-Object{Write-Host "[RELEASE ERR] $_" -ForegroundColor Red};throw "$($Errors.Count) release readiness error(s) found."}
Write-Host "`nAll AI Office v2.5 Part L Release Readiness checks passed." -ForegroundColor Green
