param(
    [Parameter(Mandatory=$true)][string]$Content,
    [string]$Scope = "global"
)

$ErrorActionPreference = "Stop"
Set-Location "E:\AI\AI-Office"

$Policy = Get-Content ".\config\memory\live-integration-policy.json" -Raw | ConvertFrom-Json

if (-not [bool]$Policy.enabled) {
    return [pscustomobject]@{
        enabled = $false
        used = $false
        context_id = ""
        result_count = 0
        context_text = ""
    }
}

$Package = & ".\scripts\memory\New-AIOfficeMemoryContextPackage.ps1" `
    -Query $Content `
    -Scope $Scope `
    -MaxItems ([int]$Policy.max_items) `
    -MaxCharacters ([int]$Policy.max_characters) `
    -PersistSnapshot:([bool]$Policy.persist_context_snapshots)

$UseContext = ([int]$Package.result_count -gt 0)

return [pscustomobject]@{
    enabled = $true
    used = $UseContext
    context_id = [string]$Package.context_id
    result_count = [int]$Package.result_count
    context_text = if ($UseContext) { [string]$Package.context_text } else { "" }
    memory_ids = @($Package.memory_ids)
}
