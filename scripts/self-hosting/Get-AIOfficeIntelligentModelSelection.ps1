param(
    [Parameter(Mandatory=$true)][string]$TaskType,
    [ValidateSet("private","sensitive","normal","public")][string]$Sensitivity = "normal",
    [ValidateSet("low","medium","high")][string]$Complexity = "medium",
    [ValidateSet("quick","balanced","quality")][string]$WorkloadProfile = "balanced",
    [switch]$DoNotPersist
)

$ErrorActionPreference = "Stop"

. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeSelfHosting.Common.ps1"
. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeModelSelection.Common.ps1"
. "E:\AI\AI-Office\scripts\self-hosting\AIOfficeHybridRouting.Common.ps1"

$Policy = Get-AIOfficeModelSelectionPolicy
$Health = Get-AIOfficeLatestLocalHealth
$LocalHealthy = ($null -ne $Health -and [string]$Health.status -eq "healthy")
$ReadyModels = Get-AIOfficeReadyLocalModels

$RequiredCapabilities = @()
$CapabilityProperty = $Policy.capability_map.PSObject.Properties[$TaskType]

if ($null -ne $CapabilityProperty) {
    $RequiredCapabilities = @($CapabilityProperty.Value)
}
else {
    $RequiredCapabilities = @("chat")
}

$Candidates = New-Object System.Collections.Generic.List[object]

foreach ($Model in $ReadyModels) {
    $Capabilities = @($Model.capabilities)
    $MatchedCapabilities = @(
        $RequiredCapabilities |
        Where-Object { $Capabilities -contains [string]$_ }
    ).Count

    $CapabilityFit = if ($RequiredCapabilities.Count -gt 0) {
        [double]$MatchedCapabilities / [double]$RequiredCapabilities.Count
    }
    else {
        1.0
    }

    $ModelSize = 0.0
    if ($null -ne $Model.resource_profile.model_size_gb) {
        $ModelSize = [double]$Model.resource_profile.model_size_gb
    }
    elseif ($null -ne $Model.resource_profile.vram_gb) {
        $ModelSize = [double]$Model.resource_profile.vram_gb
    }

    $Profile = $Policy.workload_profiles.$WorkloadProfile
    $PreferredSize = [double]$Profile.preferred_size_gb

    $ResourceFit = if ($ModelSize -le 0) {
        0.75
    }
    elseif ($ModelSize -le $PreferredSize) {
        1.0
    }
    else {
        [math]::Max(0.2, ($PreferredSize / $ModelSize))
    }

    $History = Get-AIOfficeHistoricalModelStats -Model ([string]$Model.model_name) -TaskType $TaskType

    $LatencyFit = 0.75
    if ([double]$History.average_elapsed_ms -gt 0) {
        if ([double]$History.average_elapsed_ms -le 5000) {
            $LatencyFit = 1.0
        }
        elseif ([double]$History.average_elapsed_ms -le 15000) {
            $LatencyFit = 0.8
        }
        elseif ([double]$History.average_elapsed_ms -le 30000) {
            $LatencyFit = 0.6
        }
        else {
            $LatencyFit = 0.4
        }
    }

    $PrivacyFit = if ($Sensitivity -eq "private" -or $Sensitivity -eq "sensitive") { 1.0 } else { 0.9 }
    $HistoricalFit = [double]$History.success_rate

    $Score = (
        ($CapabilityFit * [double]$Policy.weights.capability_match) +
        ($ResourceFit * [double]$Policy.weights.resource_fit) +
        ($LatencyFit * [double]$Policy.weights.latency_fit) +
        ($PrivacyFit * [double]$Policy.weights.privacy_fit) +
        ($HistoricalFit * [double]$Policy.weights.historical_success)
    ) * 100

    $Candidates.Add([pscustomobject]@{
        provider = "ollama"
        model = [string]$Model.model_name
        score = [math]::Round($Score, 2)
        capability_fit = [math]::Round($CapabilityFit, 3)
        resource_fit = [math]::Round($ResourceFit, 3)
        latency_fit = [math]::Round($LatencyFit, 3)
        privacy_fit = [math]::Round($PrivacyFit, 3)
        historical_fit = [math]::Round($HistoricalFit, 3)
        historical_samples = [int]$History.samples
    })
}

$CloudRequired = (
    $Complexity -eq "high" -and
    @("deep_reasoning","complex_strategy","long_context") -contains $TaskType
)

$SelectedProvider = ""
$SelectedModel = ""
$SelectedScore = 0.0
$Reason = ""

if ($Sensitivity -eq "private") {
    if (-not $LocalHealthy) {
        throw "Private workload requires local inference, but local inference is not healthy."
    }

    if ($Candidates.Count -eq 0) {
        throw "Private workload requires local inference, but no ready local models are registered."
    }

    $Best = @($Candidates | Sort-Object score -Descending | Select-Object -First 1)[0]
    $SelectedProvider = "ollama"
    $SelectedModel = [string]$Best.model
    $SelectedScore = [double]$Best.score
    $Reason = "Private workload forced local model selection."
}
elseif ($CloudRequired) {
    $SelectedProvider = "openclaw"
    $SelectedModel = ""
    $SelectedScore = 100
    $Reason = "High-complexity workload requires cloud-preferred execution."
}
elseif ($LocalHealthy -and $Candidates.Count -gt 0) {
    $Best = @($Candidates | Sort-Object score -Descending | Select-Object -First 1)[0]

    if ([double]$Best.score -ge 55) {
        $SelectedProvider = "ollama"
        $SelectedModel = [string]$Best.model
        $SelectedScore = [double]$Best.score
        $Reason = "Best ready local model met workload selection threshold."
    }
    else {
        $SelectedProvider = "openclaw"
        $SelectedScore = 75
        $Reason = "No local model met the minimum workload selection threshold."
    }
}
else {
    $SelectedProvider = "openclaw"
    $SelectedScore = 70
    $Reason = "Local inference unavailable or no ready local models registered."
}

$Id = New-AIOfficeSelfHostingId -Prefix "SHSEL"

$Decision = [ordered]@{
    model_selection_id = $Id
    task_type = $TaskType
    sensitivity = $Sensitivity
    complexity = $Complexity
    workload_profile = $WorkloadProfile
    selected_provider = $SelectedProvider
    selected_model = $SelectedModel
    score = [math]::Round($SelectedScore,2)
    reason = $Reason
    local_health = if ($LocalHealthy) { "healthy" } else { "unavailable" }
    candidates = @($Candidates | ForEach-Object { $_ })
    created_at = (Get-Date).ToString("o")
}

if (-not $DoNotPersist) {
    Write-AIOfficeSelfHostingJson `
        -Value $Decision `
        -Path "E:\AI\AI-Office\workspace\self-hosting\model-selections\$Id.json"
}

Write-Host "Intelligent model selection: $Id | $SelectedProvider | $SelectedModel | score=$($Decision.score)" -ForegroundColor Green
return [pscustomobject]$Decision
