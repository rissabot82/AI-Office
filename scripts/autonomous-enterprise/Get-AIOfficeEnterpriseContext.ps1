param(
    [Parameter(Mandatory=$true)][string]$EnterpriseWorkId
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\autonomous-enterprise\AIOfficeEnterprise.Common.ps1"

$Work = Get-AIOfficeEnterpriseWorkById -EnterpriseWorkId $EnterpriseWorkId

$Context = [ordered]@{
    enterprise_work_id = $EnterpriseWorkId
    title = [string]$Work.title
    domain = [string]$Work.domain
    priority = [string]$Work.priority
    explicit_context_refs = @($Work.context_refs)
    sources = [ordered]@{
        long_term_memory = (Test-Path -LiteralPath "E:\AI\AI-Office\workspace\memory" -PathType Container)
        knowledge_graph = (Test-Path -LiteralPath "E:\AI\AI-Office\workspace\knowledge-graph" -PathType Container)
        multi_agent = (Test-Path -LiteralPath "E:\AI\AI-Office\workspace\multi-agent" -PathType Container)
        operations_integrations = (Test-Path -LiteralPath "E:\AI\AI-Office\workspace\operations-integrations" -PathType Container)
        autonomous_workflows = (Test-Path -LiteralPath "E:\AI\AI-Office\workspace\autonomous-workflows" -PathType Container)
    }
    generated_at = (Get-Date).ToString("o")
}

return [pscustomobject]$Context
