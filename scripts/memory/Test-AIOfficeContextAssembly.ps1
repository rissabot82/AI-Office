param()
$ErrorActionPreference="Stop"
Set-Location "E:\AI\AI-Office"
Write-Host "`nTesting AI Office v2.6 Part D Context Assembly...`n" -ForegroundColor Cyan
$Errors=New-Object System.Collections.Generic.List[string]
$Created=New-Object System.Collections.Generic.List[string]

foreach($A in @(
 ".\config\memory\context-assembly-policy.json",
 ".\scripts\memory\New-AIOfficeContextSnapshotId.ps1",
 ".\scripts\memory\New-AIOfficeMemoryContextPackage.ps1",
 ".\scripts\memory\Test-AIOfficeContextAssembly.ps1"
)){
 if(Test-Path $A){Write-Host "[FOUND] $A" -ForegroundColor Green}else{$Errors.Add("Missing artifact: $A")}
}

try{Get-Content ".\config\memory\context-assembly-policy.json" -Raw|ConvertFrom-Json|Out-Null;Write-Host "[VALID JSON] context-assembly-policy.json" -ForegroundColor Green}catch{$Errors.Add("Invalid context-assembly-policy.json")}

try{
 $Token="contextcert"+[guid]::NewGuid().ToString("N").Substring(0,10)
 $A=& ".\scripts\memory\Save-AIOfficeMemoryRecord.ps1" -MemoryType "dealership" -Title "Elite Context Fixture" -Content ($Token+" Elite Auto Sales Wichita marketing context") -Source "certification" -Scope "CERT-MEMORY-D" -AllowDuplicate
 $B=& ".\scripts\memory\Save-AIOfficeMemoryRecord.ps1" -MemoryType "workflow" -Title "Elite Workflow Fixture" -Content ($Token+" Elite campaign workflow context") -Source "certification" -Scope "CERT-MEMORY-D" -AllowDuplicate
 $Created.Add([string]$A.memory_id);$Created.Add([string]$B.memory_id)

 $P=& ".\scripts\memory\New-AIOfficeMemoryContextPackage.ps1" -Query ($Token+" Elite workflow") -Scope "CERT-MEMORY-D" -MaxItems 8 -MaxCharacters 8000 -PersistSnapshot

 if([int]$P.result_count-lt2){throw "Context package returned too few memories."}
 if(-not([string]$P.context_text).StartsWith("MEMORY CONTEXT")){throw "Context header missing."}
 if(-not([string]$P.context_text).Contains("END MEMORY CONTEXT")){throw "Context footer missing."}
 if(-not([string]$P.context_text).Contains("reference context only")){throw "Reference-only safety boundary missing."}
 if([int]$P.character_count-gt[int]$P.max_characters){throw "Context package exceeded character budget."}
 Write-Host "[ASSEMBLY OK] Relevant memories assembled into bounded context." -ForegroundColor Green
}catch{$Errors.Add($_.Exception.Message)}

try{
 $Token="budgetcert"+[guid]::NewGuid().ToString("N").Substring(0,10)
 $Long=& ".\scripts\memory\Save-AIOfficeMemoryRecord.ps1" -MemoryType "project" -Title "Long Context Fixture" -Content ($Token+" "+("X"*5000)) -Source "certification" -Scope "CERT-MEMORY-D-LONG" -AllowDuplicate
 $Created.Add([string]$Long.memory_id)
 $P=& ".\scripts\memory\New-AIOfficeMemoryContextPackage.ps1" -Query $Token -Scope "CERT-MEMORY-D-LONG" -MaxItems 5 -MaxCharacters 900
 if([int]$P.character_count-gt900){throw "Context budget exceeded."}
 Write-Host "[BUDGET OK] Context character budget enforced." -ForegroundColor Green
}catch{$Errors.Add($_.Exception.Message)}

try{
 $Runtime=Get-Content ".\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" -Raw
 if($Runtime.Contains("New-AIOfficeMemoryContextPackage.ps1")){throw "Part D must not inject memory into live conversations yet."}
 Write-Host "[PRODUCTION SAFETY OK] Live conversational runtime remains unchanged." -ForegroundColor Green
}catch{$Errors.Add($_.Exception.Message)}

foreach($Id in @($Created|Select-Object -Unique)){try{& ".\scripts\memory\Disable-AIOfficeMemoryRecord.ps1" -MemoryId $Id}catch{}}

if($Errors.Count-gt0){$Errors|ForEach-Object{Write-Host "[MEMORY ERR] $_" -ForegroundColor Red};throw "$($Errors.Count) Context Assembly error(s) found."}
Write-Host "`nAll AI Office v2.6 Part D Context Assembly checks passed." -ForegroundColor Green
