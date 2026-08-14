param()
$ErrorActionPreference="Stop"
Set-Location "E:\AI\AI-Office"

$Latest=Get-ChildItem ".\workspace\intelligence\certifications\CERT-INTELLIGENCE-*.json" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if(-not $Latest){throw "No v2.5 certification found."}
$Cert=Get-Content $Latest.FullName -Raw|ConvertFrom-Json
if([string]$Cert.status-ne"passed"-or[int]$Cert.passed_checks-lt14-or[int]$Cert.failed_checks-ne0){throw "Latest v2.5 certification is not release-ready."}

$ManifestPath=".\config\intelligence\release-manifest.json"
$M=Get-Content $ManifestPath -Raw|ConvertFrom-Json
$M.status="released"
$M|Add-Member certification_id ([string]$Cert.certification_id) -Force
$M|Add-Member released_at ((Get-Date).ToString("o")) -Force
$M|ConvertTo-Json -Depth 40|Set-Content $ManifestPath -Encoding UTF8

$VP=".\config\identity\version.json"
if(Test-Path $VP){
 $V=Get-Content $VP -Raw|ConvertFrom-Json
 $V.version="2.5.0";$V.release_name="Intelligence Upgrade";$V.status="released";$V.next_planned_milestone="Memory & Context Integration"
 $V|Add-Member released_at ((Get-Date).ToString("o")) -Force
 $V|ConvertTo-Json -Depth 40|Set-Content $VP -Encoding UTF8
}

& ".\scripts\intelligence\Sync-AIOfficeV25ProjectDocs.ps1"
& ".\scripts\intelligence\Update-AIOfficeIntelligenceDashboardData.ps1"|Out-Null
Write-Host "AI Office v2.5 Intelligence Upgrade RELEASED." -ForegroundColor Green
Write-Host ("Certification: "+$Cert.certification_id) -ForegroundColor Cyan
