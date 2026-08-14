param()

$ErrorActionPreference = "Stop"

$PolicyPath = "E:\AI\AI-Office\config\intelligence\intelligence-policy.json"
$SuitePath = "E:\AI\AI-Office\config\intelligence\benchmark-suite.json"

$Policy = Get-Content -LiteralPath $PolicyPath -Raw | ConvertFrom-Json
$Suite = Get-Content -LiteralPath $SuitePath -Raw | ConvertFrom-Json

return [pscustomobject]@{
    version = [string]$Policy.version
    release_name = [string]$Policy.release_name
    default_quality_tier = [string]$Policy.architecture.default_quality_tier
    local_first = [bool]$Policy.architecture.preserve_local_first
    escalation_enabled = [bool]$Policy.architecture.allow_escalation
    task_families = @($Policy.task_families)
    benchmark_cases = @($Suite.cases).Count
}
