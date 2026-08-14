param(
 [Parameter(Mandatory=$true)][string]$Content
)
$ErrorActionPreference="Stop"
$Policy=Get-Content "E:\AI\AI-Office\config\memory\capture-policy.json" -Raw|ConvertFrom-Json
$Text=$Content.Trim()

if(-not [bool]$Policy.enabled){
 return [pscustomobject]@{capture=$false;content="";matched_phrase=""}
}

foreach($Phrase in @($Policy.explicit_phrases)){
 $Index=$Text.IndexOf([string]$Phrase,[System.StringComparison]::OrdinalIgnoreCase)
 if($Index -ge 0){
   $Value=$Text.Substring($Index+([string]$Phrase).Length).Trim()
   $Value=$Value.TrimStart(':','-',' ',[char]9)
   if(-not [string]::IsNullOrWhiteSpace($Value)){
     return [pscustomobject]@{
       capture=$true
       content=$Value
       matched_phrase=[string]$Phrase
     }
   }
 }
}
return [pscustomobject]@{capture=$false;content="";matched_phrase=""}
