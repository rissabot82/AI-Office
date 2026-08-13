param(
    [Parameter(Mandatory=$true)][string]$TaskType,
    [ValidateSet("private","sensitive","normal","public")][string]$Sensitivity = "normal",
    [ValidateSet("low","medium","high")][string]$Complexity = "medium",
    [ValidateSet("","local_only","local_preferred","balanced","cloud_preferred","cloud_only")][string]$ExplicitMode = "",
    [string]$LocalModel = "",
    [switch]$DoNotPersist
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"
. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeHybridRouting.Common.ps1"

$Policy = Get-AIOfficeHybridRoutingPolicy
$Health = Get-AIOfficeLatestLocalHealth
$LocalHealthy = ($null -ne $Health -and [string]$Health.status -eq "healthy")

if ([string]::IsNullOrWhiteSpace($LocalModel)) {
    $LocalModel = Get-AIOfficeDefaultLocalModel
}

$Mode = ""
$Provider = ""
$Reason = ""

if (-not [string]::IsNullOrWhiteSpace($ExplicitMode)) {
    $Mode = $ExplicitMode
    $Reason = "Explicit routing mode requested."
}
elseif ($Sensitivity -eq "private") {
    $Mode = "local_only"
    $Reason = "Private context requires local-only execution."
}
elseif ($Sensitivity -eq "sensitive") {
    $Mode = "local_preferred"
    $Reason = "Sensitive context prefers local execution."
}
elseif (@($Policy.task_types.cloud_preferred) -contains $TaskType) {
    $Mode = "cloud_preferred"
    $Reason = "Task type is configured for cloud-preferred execution."
}
elseif (@($Policy.task_types.local_preferred) -contains $TaskType) {
    $Mode = "local_preferred"
    $Reason = "Task type is configured for local-preferred execution."
}
else {
    $Mode = [string]$Policy.complexity.$Complexity
    if ([string]::IsNullOrWhiteSpace($Mode)) {
        $Mode = [string]$Policy.routing.default_mode
    }
    $Reason = "Routing selected from task complexity/default policy."
}

switch ($Mode) {
    "local_only" {
        if (-not $LocalHealthy) {
            throw "Local-only routing requested but local inference is not healthy."
        }
        $Provider = "ollama"
    }
    "local_preferred" {
        if ($LocalHealthy) {
            $Provider = "ollama"
        }
        else {
            $Provider = "openclaw"
            $Reason += " Local runtime unavailable; cloud fallback selected."
        }
    }
    "balanced" {
        if ($Complexity -eq "high") {
            $Provider = "openclaw"
        }
        elseif ($LocalHealthy) {
            $Provider = "ollama"
        }
        else {
            $Provider = "openclaw"
        }
    }
    "cloud_preferred" {
        $Provider = "openclaw"
    }
    "cloud_only" {
        $Provider = "openclaw"
    }
    default {
        throw "Unsupported routing mode: $Mode"
    }
}

$Id = New-AIOfficeSelfHostingId -Prefix "SHDEC"

$Decision = [ordered]@{
    routing_decision_id = $Id
    task_type = $TaskType
    sensitivity = $Sensitivity
    complexity = $Complexity
    explicit_mode = $ExplicitMode
    selected_provider = $Provider
    selected_mode = $Mode
    selected_model = if ($Provider -eq "ollama") { $LocalModel } else { "" }
    reason = $Reason
    local_health = if ($LocalHealthy) { "healthy" } else { "unavailable" }
    created_at = (Get-Date).ToString("o")
}

if (-not $DoNotPersist) {
    Write-AIOfficeSelfHostingJson `
        -Value $Decision `
        -Path "E:\AI\AI-Office\workspace\self-hosting\routing-decisions\$Id.json"
}

Write-Host "Routing decision: $Id | $Provider | $Mode" -ForegroundColor Green
return [pscustomobject]$Decision
