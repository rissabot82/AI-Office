param()
$ErrorActionPreference="Stop"
Set-Location "E:\AI\AI-Office"

Write-Host ""
Write-Host "Testing AI Office v2.6 Part G Controlled Memory Capture..." -ForegroundColor Cyan
Write-Host ""

$Errors=New-Object System.Collections.Generic.List[string]
$CreatedIds=New-Object System.Collections.Generic.List[string]

foreach($Artifact in @(
 ".\config\memory\capture-policy.json",
 ".\scripts\memory\Get-AIOfficeExplicitMemoryCapture.ps1",
 ".\scripts\memory\Save-AIOfficeExplicitConversationMemory.ps1",
 ".\scripts\memory\Test-AIOfficeControlledMemoryCapture.ps1"
)){
 if(Test-Path $Artifact){Write-Host "[FOUND] $Artifact" -ForegroundColor Green}else{$Errors.Add("Missing artifact: $Artifact")}
}

try{
 $Policy=Get-Content ".\config\memory\capture-policy.json" -Raw|ConvertFrom-Json
 if([bool]$Policy.allow_automatic_inference){throw "Automatic inferred memory capture must remain disabled in v2.6."}
 if(-not [bool]$Policy.require_explicit_user_intent){throw "Explicit user intent requirement is disabled."}
 Write-Host "[POLICY OK] Capture is explicit-only." -ForegroundColor Green
}catch{$Errors.Add($_.Exception.Message)}

try{
 $Token="capturecert"+[guid]::NewGuid().ToString("N").Substring(0,10)
 $Result=& ".\scripts\memory\Save-AIOfficeExplicitConversationMemory.ps1" `
   -Content ("Remember that "+$Token+" is the Part G certification token.") `
   -Title "Part G Explicit Capture Fixture" `
   -Scope "CERT-MEMORY-G"

 if(-not [bool]$Result.captured){throw "Explicit memory request was not captured."}
 $CreatedIds.Add([string]$Result.memory_id)

 $Search=@(& ".\scripts\memory\Search-AIOfficeMemory.ps1" -Query $Token -Scope "CERT-MEMORY-G" -MaxItems 5)
 if($Search.Count-lt1){throw "Captured memory could not be retrieved."}
 Write-Host "[EXPLICIT CAPTURE OK] User-approved memory saved and retrievable." -ForegroundColor Green
}catch{$Errors.Add($_.Exception.Message)}

try{
 $Token="nocapture"+[guid]::NewGuid().ToString("N").Substring(0,10)
 $Result=& ".\scripts\memory\Save-AIOfficeExplicitConversationMemory.ps1" `
   -Content ("I bought "+$Token+" today.") `
   -Title "Part G Negative Fixture" `
   -Scope "CERT-MEMORY-G"
 if([bool]$Result.captured){throw "Ordinary conversation was incorrectly captured as durable memory."}
 Write-Host "[NEGATIVE CAPTURE OK] Ordinary conversation was not stored." -ForegroundColor Green
}catch{$Errors.Add($_.Exception.Message)}

try{
 $Runtime=Get-Content ".\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" -Raw
 if($Runtime.Contains("Save-AIOfficeExplicitConversationMemory.ps1")){
   throw "Part G installer must not silently modify live conversation runtime."
 }
 Write-Host "[PRODUCTION SAFETY OK] Live runtime remains unchanged pending explicit wiring." -ForegroundColor Green
}catch{$Errors.Add($_.Exception.Message)}

foreach($Id in $CreatedIds){
 try{& ".\scripts\memory\Disable-AIOfficeMemoryRecord.ps1" -MemoryId $Id}catch{}
}

if($Errors.Count-gt0){
 foreach($Item in $Errors){Write-Host "[MEMORY ERR] $Item" -ForegroundColor Red}
 throw "$($Errors.Count) Controlled Memory Capture error(s) found."
}

Write-Host ""
Write-Host "All AI Office v2.6 Part G Controlled Memory Capture checks passed." -ForegroundColor Green
Write-Host "Explicit capture engine is certified; live runtime was intentionally not altered." -ForegroundColor Yellow
