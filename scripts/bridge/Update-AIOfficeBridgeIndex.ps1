param()

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "AIOfficeBridge.Common.ps1")

$Root = Get-AIOfficeBridgeRoot
Set-Location $Root

$Identity = Read-AIOfficeBridgeJson `
    -Path ".\config\bridge\bridge-identity.json"

$Policy = Get-AIOfficeBridgePolicy

if ($null -eq $Identity -or $null -eq $Policy) {
    throw "Bridge identity or policy could not be loaded."
}

$RequestFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\bridge\requests" `
        -Filter "BRQ-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$ResultFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\bridge\results" `
        -Filter "BRR-*.json" `
        -File `
        -ErrorAction SilentlyContinue
)

$ArtifactFiles = @(
    Get-ChildItem `
        -LiteralPath ".\workspace\bridge\artifacts" `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue
)

$LatestRequest = $RequestFiles |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

$LatestResult = $ResultFiles |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

$GatewayReachable = Test-AIOfficeOpenClawGatewayPort `
    -HostName ([string]$Policy.transport.host) `
    -Port ([int]$Policy.transport.port)

$Index = [ordered]@{
    schema_version = "1.0.0"
    updated_at = (Get-Date).ToString("o")
    bridge_id = [string]$Identity.bridge_id
    status = if ($GatewayReachable) { "ready" } else { "gateway_unreachable" }
    pending_request_count = [int]$RequestFiles.Count
    completed_result_count = [int]$ResultFiles.Count
    artifact_count = [int]$ArtifactFiles.Count
    latest_request_id = if ($null -ne $LatestRequest) { $LatestRequest.BaseName } else { "" }
    latest_result_id = if ($null -ne $LatestResult) { $LatestResult.BaseName } else { "" }
    gateway_url = [string]$Policy.transport.url
    gateway_reachable = $GatewayReachable
}

Write-AIOfficeBridgeJson `
    -Value $Index `
    -Path ".\workspace\bridge\bridge-index.json"

Write-Host (
    "Bridge index updated: " +
    $Index.status +
    " | " +
    $RequestFiles.Count.ToString() +
    " request(s)"
) -ForegroundColor Green

return [pscustomobject]$Index
