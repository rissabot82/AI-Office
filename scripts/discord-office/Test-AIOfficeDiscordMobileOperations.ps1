param([switch]$PublishRelease)
$ErrorActionPreference="Stop"
Write-Host ""
Write-Host "Testing AI Office v2.4 Discord Mobile Operations..." -ForegroundColor Cyan
Write-Host ""

if($PublishRelease){
    $Certification=& "E:\AI\AI-Office\scripts\discord-office\Publish-AIOfficeDiscordMobileOperationsRelease.ps1"
}else{
    $Certification=& "E:\AI\AI-Office\scripts\discord-office\Certify-AIOfficeDiscordMobileOperations.ps1"
}

$Certification|Format-List

if([string]$Certification.status -ne "certified"){
    throw "AI Office v2.4 Discord Mobile Operations certification failed."
}

Write-Host ""
Write-Host "All AI Office v2.4 Discord Mobile Operations checks passed." -ForegroundColor Green
