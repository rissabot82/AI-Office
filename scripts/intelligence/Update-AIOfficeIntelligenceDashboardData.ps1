param()
$ErrorActionPreference="Stop"
$CertDir="E:\AI\AI-Office\workspace\intelligence\certifications"
$Latest=Get-ChildItem $CertDir -Filter "CERT-INTELLIGENCE-*.json" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$Cert=$null
if($Latest){$Cert=Get-Content $Latest.FullName -Raw|ConvertFrom-Json}
$Ops=& "E:\AI\AI-Office\scripts\intelligence\Get-AIOfficeIntelligenceOperationsStatus.ps1"
$Payload=[ordered]@{
 module="intelligence";version="2.5.0";release_name="Intelligence Upgrade";
 certification_status=if($Cert){[string]$Cert.status}else{"missing"};
 certification_id=if($Cert){[string]$Cert.certification_id}else{""};
 passed_checks=if($Cert){[int]$Cert.passed_checks}else{0};
 failed_checks=if($Cert){[int]$Cert.failed_checks}else{0};
 tracked_selections=[int]$Ops.tracked_selections;
 intelligent_turns=[int]$Ops.intelligent_turns;
 fallback_turns=[int]$Ops.fallback_turns;
 escalation_recommendations=[int]$Ops.escalation_recommendations;
 next_release="2.6.0";next_milestone="Memory & Context Integration";
 updated_at=(Get-Date).ToString("o")
}
$Path="E:\AI\AI-Office\dashboard\public\data\intelligence.json"
New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force|Out-Null
$Payload|ConvertTo-Json -Depth 30|Set-Content -LiteralPath $Path -Encoding UTF8
Write-Host "[DASHBOARD DATA] intelligence.json" -ForegroundColor Green
return [pscustomobject]$Payload
