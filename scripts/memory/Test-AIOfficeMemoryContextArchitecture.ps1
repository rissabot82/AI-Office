param()
$ErrorActionPreference="Stop"
Set-Location "E:\AI\AI-Office"
Write-Host "`nTesting AI Office v2.6 Part A Memory & Context Architecture...`n" -ForegroundColor Cyan
$Errors=New-Object System.Collections.Generic.List[string]

foreach($Json in @(
 ".\config\memory\memory-policy.json",
 ".\config\memory\memory-record-schema.json",
 ".\workspace\memory\indexes\memory-index.json"
)){
 try{Get-Content $Json -Raw|ConvertFrom-Json|Out-Null;Write-Host "[VALID JSON] $Json" -ForegroundColor Green}
 catch{$Errors.Add("Invalid JSON: $Json")}
}

foreach($Script in @(
 ".\scripts\memory\Get-AIOfficeMemoryPolicy.ps1",
 ".\scripts\memory\Get-AIOfficeMemoryArchitecture.ps1",
 ".\scripts\memory\Test-AIOfficeMemoryContextArchitecture.ps1"
)){
 if(Test-Path $Script){Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green}else{$Errors.Add("Missing script: $Script")}
}

try{
 $A=& ".\scripts\memory\Get-AIOfficeMemoryArchitecture.ps1"
 if([string]$A.version-ne"2.6.0"){throw "Unexpected version."}
 if(@($A.memory_types).Count-ne5){throw "Expected 5 memory types."}
 if([bool]$A.enabled){throw "Part A memory runtime must remain disabled."}
 Write-Host "[ARCHITECTURE OK] 5 memory types | runtime disabled." -ForegroundColor Green
}catch{$Errors.Add($_.Exception.Message)}

try{
 $P=Get-Content ".\config\memory\memory-policy.json" -Raw|ConvertFrom-Json
 if(-not[bool]$P.safety.require_explicit_user_approval_for_sensitive_memory){throw "Sensitive approval safeguard disabled."}
 if(-not[bool]$P.safety.do_not_store_secrets){throw "Secret-storage safeguard disabled."}
 Write-Host "[SAFETY OK] Sensitive approval + secret exclusion enabled." -ForegroundColor Green
}catch{$Errors.Add($_.Exception.Message)}

try{
 $Runtime=Get-Content ".\scripts\conversational-office\Invoke-AIOfficeConversationTurn.ps1" -Raw
 if(-not $Runtime.Contains("Invoke-AIOfficeQualityControlledInference.ps1")){throw "v2.5.1 runtime marker missing."}
 Write-Host "[PRODUCTION SAFETY OK] v2.5.1 runtime unchanged." -ForegroundColor Green
}catch{$Errors.Add($_.Exception.Message)}

if($Errors.Count-gt0){$Errors|ForEach-Object{Write-Host "[MEMORY ERR] $_" -ForegroundColor Red};throw "$($Errors.Count) Memory & Context Architecture error(s) found."}
Write-Host "`nAll AI Office v2.6 Part A Memory & Context Architecture checks passed." -ForegroundColor Green
