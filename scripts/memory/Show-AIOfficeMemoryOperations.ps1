param()

$Ops=& "E:\AI\AI-Office\scripts\memory\Get-AIOfficeMemoryOperations.ps1"

Write-Host ""
Write-Host "AI Office Memory Operations" -ForegroundColor Cyan
Write-Host "---------------------------"
Write-Host ("Status:              "+$Ops.status)
Write-Host ("Total records:       "+$Ops.total_records)
Write-Host ("Enabled:             "+$Ops.enabled_records)
Write-Host ("Disabled:            "+$Ops.disabled_records)
Write-Host ("Projects:            "+$Ops.project_memories)
Write-Host ("Dealerships:         "+$Ops.dealership_memories)
Write-Host ("Organizations:       "+$Ops.organization_memories)
Write-Host ("Workflows:           "+$Ops.workflow_memories)
Write-Host ("User-approved:       "+$Ops.user_approved_memories)
Write-Host ("Context snapshots:   "+$Ops.context_snapshots)
Write-Host ("Latest context:      "+$Ops.latest_context_id)
Write-Host ("Latest context hits: "+$Ops.latest_context_results)
Write-Host ""

return $Ops
