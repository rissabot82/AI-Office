param()
$ErrorActionPreference="Stop"
Set-Location "E:\AI\AI-Office"

$Latest=Get-ChildItem ".\workspace\intelligence\certifications\CERT-HOTFIX-*.json" -File -ErrorAction SilentlyContinue|Sort-Object LastWriteTime -Descending|Select-Object -First 1
if(-not $Latest){throw "No v2.5.1 hotfix certification found."}
$Cert=Get-Content $Latest.FullName -Raw|ConvertFrom-Json
if([string]$Cert.status-ne"passed"-or[int]$Cert.failed_checks-ne0){throw "Latest hotfix certification is not release-ready."}

$MPath=".\config\intelligence\hotfix-manifest.json"
$M=Get-Content $MPath -Raw|ConvertFrom-Json
$M.status="released"
$M|Add-Member certification_id ([string]$Cert.certification_id) -Force
$M|Add-Member released_at ((Get-Date).ToString("o")) -Force
$M|ConvertTo-Json -Depth 30|Set-Content $MPath -Encoding UTF8

$VPath=".\config\identity\version.json"
$V=Get-Content $VPath -Raw|ConvertFrom-Json
$V.version="2.5.1"
$V.release_name="Discord Reliability Hotfix"
$V.status="released"
$V|Add-Member previous_version "2.5.0" -Force
$V|Add-Member released_at ((Get-Date).ToString("o")) -Force
$V|ConvertTo-Json -Depth 30|Set-Content $VPath -Encoding UTF8

Write-Host "AI Office v2.5.1 Discord Reliability Hotfix RELEASED." -ForegroundColor Green
Write-Host ("Certification: "+$Cert.certification_id) -ForegroundColor Cyan
