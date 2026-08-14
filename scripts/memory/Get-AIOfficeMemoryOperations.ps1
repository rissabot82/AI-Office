param()

$ErrorActionPreference="Stop"
Set-Location "E:\AI\AI-Office"

$Policy=Get-Content ".\config\memory\operations-policy.json" -Raw|ConvertFrom-Json
$Index=Get-Content ".\workspace\memory\indexes\memory-index.json" -Raw|ConvertFrom-Json

$Records=@($Index.records)
$Enabled=@($Records|Where-Object{$_.enabled -eq $true})
$Disabled=@($Records|Where-Object{$_.enabled -ne $true})

$ByType=@{}
foreach($Type in @("project","dealership","organization","workflow","user_approved")){
    $ByType[$Type]=@($Enabled|Where-Object{[string]$_.memory_type -eq $Type}).Count
}

$Snapshots=@(
    Get-ChildItem ".\workspace\memory\context-snapshots\CTX-*.json" -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending
)

$LatestSnapshot=$null
if($Snapshots.Count -gt 0){
    try{$LatestSnapshot=Get-Content $Snapshots[0].FullName -Raw|ConvertFrom-Json}catch{}
}

return [pscustomobject]@{
    version="2.6.0"
    status="healthy"
    total_records=$Records.Count
    enabled_records=$Enabled.Count
    disabled_records=$Disabled.Count
    project_memories=[int]$ByType["project"]
    dealership_memories=[int]$ByType["dealership"]
    organization_memories=[int]$ByType["organization"]
    workflow_memories=[int]$ByType["workflow"]
    user_approved_memories=[int]$ByType["user_approved"]
    context_snapshots=$Snapshots.Count
    latest_context_id=if($null-ne$LatestSnapshot){[string]$LatestSnapshot.context_id}else{""}
    latest_context_results=if($null-ne$LatestSnapshot){[int]$LatestSnapshot.result_count}else{0}
    checked_at=(Get-Date).ToString("o")
}
