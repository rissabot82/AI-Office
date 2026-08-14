param()

$ErrorActionPreference="Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.6 Part F Memory Operations & Observability..." -ForegroundColor Cyan
Write-Host ""

$Errors=New-Object System.Collections.Generic.List[string]
$CreatedId=$null

foreach($Artifact in @(
 ".\config\memory\operations-policy.json",
 ".\scripts\memory\Get-AIOfficeMemoryOperations.ps1",
 ".\scripts\memory\Measure-AIOfficeMemoryRetrieval.ps1",
 ".\scripts\memory\Show-AIOfficeMemoryOperations.ps1",
 ".\scripts\memory\Test-AIOfficeMemoryOperationsObservability.ps1"
)){
 if(Test-Path $Artifact){Write-Host "[FOUND] $Artifact" -ForegroundColor Green}else{$Errors.Add("Missing artifact: $Artifact")}
}

try{
 Get-Content ".\config\memory\operations-policy.json" -Raw|ConvertFrom-Json|Out-Null
 Write-Host "[VALID JSON] operations-policy.json" -ForegroundColor Green
}catch{$Errors.Add("Invalid operations-policy.json")}

try{
 $Ops=& ".\scripts\memory\Get-AIOfficeMemoryOperations.ps1"
 if([int]$Ops.total_records-lt0){throw "Invalid memory record count."}
 if([int]$Ops.enabled_records+[int]$Ops.disabled_records-ne[int]$Ops.total_records){throw "Memory counts do not reconcile."}
 Write-Host "[OPERATIONS OK] Memory counts reconcile." -ForegroundColor Green
}catch{$Errors.Add($_.Exception.Message)}

try{
 $Token="opscert"+[guid]::NewGuid().ToString("N").Substring(0,10)
 $Mem=& ".\scripts\memory\Save-AIOfficeMemoryRecord.ps1" -MemoryType "project" -Title "Operations Fixture" -Content ($Token+" operations observability fixture") -Source "certification" -Scope "CERT-MEMORY-F" -AllowDuplicate
 $CreatedId=[string]$Mem.memory_id

 $Measure=& ".\scripts\memory\Measure-AIOfficeMemoryRetrieval.ps1" -Query $Token -Scope "CERT-MEMORY-F"
 if([int]$Measure.result_count-lt1){throw "Measured retrieval returned no results."}
 if([double]$Measure.elapsed_ms-lt0){throw "Invalid retrieval timing."}
 Write-Host ("[TIMING OK] Retrieval "+$Measure.elapsed_ms+" ms | results="+$Measure.result_count) -ForegroundColor Green
}catch{$Errors.Add($_.Exception.Message)}

try{
 $Runtime=Get-Content ".\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" -Raw
 foreach($Marker in @("memory_used","memory_context_id","memory_result_count")){
   if(-not$Runtime.Contains($Marker)){throw "Runtime missing memory telemetry marker: $Marker"}
 }
 Write-Host "[RUNTIME TELEMETRY OK] Turn metadata exposes memory usage." -ForegroundColor Green
}catch{$Errors.Add($_.Exception.Message)}

if($CreatedId){
 try{& ".\scripts\memory\Disable-AIOfficeMemoryRecord.ps1" -MemoryId $CreatedId}catch{}
}

if($Errors.Count-gt0){
 foreach($Item in $Errors){Write-Host "[MEMORY ERR] $Item" -ForegroundColor Red}
 throw "$($Errors.Count) Memory Operations & Observability error(s) found."
}

Write-Host ""
Write-Host "All AI Office v2.6 Part F Memory Operations & Observability checks passed." -ForegroundColor Green
