param(
    [Parameter(Mandatory = $true)]
    [string]$TaskId,

    [Parameter(Mandatory = $false)]
    [switch]$Apply,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$ShowScores
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

function Get-SafeText {
    param(
        [Parameter(Mandatory = $false)]
        $Value
    )

    if ($null -eq $Value) {
        return ""
    }

    if ($Value -is [System.Array]) {
        return (($Value | ForEach-Object { [string]$_ }) -join " ")
    }

    return [string]$Value
}

function Test-KeywordMatch {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [string]$Keyword
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    if ([string]::IsNullOrWhiteSpace($Keyword)) {
        return $false
    }

    return (
        $Text.IndexOf(
            $Keyword,
            [System.StringComparison]::OrdinalIgnoreCase
        ) -ge 0
    )
}

function Find-TaskFolder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RequestedTaskId
    )

    $workflowFolders = @(
        "inbox",
        "active",
        "review",
        "approved",
        "outbox",
        "completed",
        "failed",
        "archive"
    )

    foreach ($workflowFolder in $workflowFolders) {
        $candidate = Join-Path `
            ".\workspace\$workflowFolder" `
            $RequestedTaskId

        if (Test-Path -LiteralPath $candidate -PathType Container) {
            return (Resolve-Path $candidate).Path
        }
    }

    return $null
}

function Get-AgentScores {
    param(
        [Parameter(Mandatory = $true)]
        $Task,

        [Parameter(Mandatory = $true)]
        $RoutingRules,

        [Parameter(Mandatory = $true)]
        $Policy
    )

    $title = Get-SafeText $Task.title
    $description = Get-SafeText $Task.description
    $tags = Get-SafeText $Task.tags
    $notes = Get-SafeText $Task.notes

    $results = @()

    foreach ($rule in $RoutingRules.rules) {
        $score = 0
        $matchedKeywords = @()
        $matchDetails = @()

        foreach ($keywordValue in $rule.keywords) {
            $keyword = [string]$keywordValue
            $keywordScore = 0
            $locations = @()

            if (Test-KeywordMatch -Text $title -Keyword $keyword) {
                $keywordScore += [int]$Policy.weights.title_keyword
                $locations += "title"
            }

            if (Test-KeywordMatch -Text $description -Keyword $keyword) {
                $keywordScore += [int]$Policy.weights.description_keyword
                $locations += "description"
            }

            if (Test-KeywordMatch -Text $tags -Keyword $keyword) {
                $keywordScore += [int]$Policy.weights.tag_keyword
                $locations += "tags"
            }

            if (Test-KeywordMatch -Text $notes -Keyword $keyword) {
                $keywordScore += [int]$Policy.weights.note_keyword
                $locations += "notes"
            }

            if (
                $keywordScore -gt 0 -and
                $keyword.Contains(" ")
            ) {
                $keywordScore += [int]$Policy.weights.multiword_bonus
            }

            if ($keywordScore -gt 0) {
                $score += $keywordScore
                $matchedKeywords += $keyword
                $matchDetails += (
                    "{0} [{1}] +{2}" -f
                    $keyword,
                    ($locations -join ", "),
                    $keywordScore
                )
            }
        }

        $results += [PSCustomObject]@{
            agent = [string]$rule.agent
            department = [string]$rule.department
            score = $score
            matched_keywords = $matchedKeywords
            match_details = $matchDetails
        }
    }

    return @(
        $results |
        Sort-Object `
            @{ Expression = "score"; Descending = $true },
            @{ Expression = "agent"; Descending = $false }
    )
}

function Get-RoutingDecision {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Scores,

        [Parameter(Mandatory = $true)]
        $Policy
    )

    $positiveScores = @(
        $Scores | Where-Object {
            $_.score -gt 0
        }
    )

    if ($positiveScores.Count -eq 0) {
        return [PSCustomObject]@{
            agent = [string]$Policy.default_agent
            department = [string]$Policy.default_department
            confidence = "none"
            score = 0
            margin = 0
            reason = "No routing keywords matched. The task requires Chief of Staff review."
            matched_keywords = @()
        }
    }

    $top = $positiveScores[0]

    if ($positiveScores.Count -gt 1) {
        $second = $positiveScores[1]
        $margin = [int]$top.score - [int]$second.score
    }
    else {
        $second = $null
        $margin = [int]$top.score
    }

    $topTies = @(
        $positiveScores | Where-Object {
            $_.score -eq $top.score
        }
    )

    if (
        $topTies.Count -gt 1 -and
        $Policy.rules.send_ties_to_chief_of_staff
    ) {
        return [PSCustomObject]@{
            agent = [string]$Policy.mixed_task_agent
            department = [string]$Policy.mixed_task_department
            confidence = "mixed"
            score = [int]$top.score
            margin = 0
            reason = (
                "Multiple agents tied for the highest score: {0}" -f
                (($topTies.agent) -join ", ")
            )
            matched_keywords = @(
                $topTies |
                ForEach-Object {
                    $_.matched_keywords
                } |
                Select-Object -Unique
            )
        }
    }

    $confidence = "low"

    if (
        [int]$top.score -ge
            [int]$Policy.confidence_levels.high.minimum_score -and
        $margin -ge
            [int]$Policy.confidence_levels.high.minimum_margin
    ) {
        $confidence = "high"
    }
    elseif (
        [int]$top.score -ge
            [int]$Policy.confidence_levels.medium.minimum_score -and
        $margin -ge
            [int]$Policy.confidence_levels.medium.minimum_margin
    ) {
        $confidence = "medium"
    }

    $reason = "The $($top.agent) agent received the highest routing score."

    if ($second) {
        $reason += (
            " It scored {0}, compared with {1} for {2}." -f
            $top.score,
            $second.score,
            $second.agent
        )
    }
    else {
        $reason += " It was the only agent with a positive score."
    }

    return [PSCustomObject]@{
        agent = [string]$top.agent
        department = [string]$top.department
        confidence = $confidence
        score = [int]$top.score
        margin = $margin
        reason = $reason
        matched_keywords = @($top.matched_keywords)
    }
}

# ------------------------------------------------------------
# Load required files
# ------------------------------------------------------------

$routingRulesPath = ".\config\tasks\routing-rules.json"
$routingPolicyPath = ".\config\tasks\routing-policy.json"
$agentRegistryPath = ".\config\agents\registry.json"
$taskRegisterPath = ".\workspace\task-register.json"

$requiredFiles = @(
    $routingRulesPath,
    $routingPolicyPath,
    $agentRegistryPath,
    $taskRegisterPath
)

foreach ($requiredFile in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required file not found: $requiredFile"
    }
}

$routingRules = Get-Content `
    -LiteralPath $routingRulesPath `
    -Raw |
    ConvertFrom-Json

$policy = Get-Content `
    -LiteralPath $routingPolicyPath `
    -Raw |
    ConvertFrom-Json

$agentRegistry = Get-Content `
    -LiteralPath $agentRegistryPath `
    -Raw |
    ConvertFrom-Json

# ------------------------------------------------------------
# Locate and load task
# ------------------------------------------------------------

$taskFolder = Find-TaskFolder -RequestedTaskId $TaskId

if ([string]::IsNullOrWhiteSpace($taskFolder)) {
    throw "Task folder not found: $TaskId"
}

$taskJsonPath = Join-Path $taskFolder "task.json"

if (-not (Test-Path -LiteralPath $taskJsonPath -PathType Leaf)) {
    throw "task.json was not found for task $TaskId."
}

$task = Get-Content `
    -LiteralPath $taskJsonPath `
    -Raw |
    ConvertFrom-Json

# ------------------------------------------------------------
# Calculate routing result
# ------------------------------------------------------------

$scores = Get-AgentScores `
    -Task $task `
    -RoutingRules $routingRules `
    -Policy $policy

$decision = Get-RoutingDecision `
    -Scores $scores `
    -Policy $policy

$registeredAgent = @(
    $agentRegistry.agents | Where-Object {
        $_.id -eq $decision.agent
    }
)

if ($registeredAgent.Count -eq 0) {
    throw (
        "Routing selected an agent that is not in the registry: {0}" -f
        $decision.agent
    )
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " AI Office Routing Recommendation" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Task ID:       $TaskId"
Write-Host "Title:         $($task.title)"
Write-Host "Current Agent: $($task.assigned_agent)"
Write-Host ""
Write-Host "Recommended Agent:      $($decision.agent)" -ForegroundColor Green
Write-Host "Recommended Department: $($decision.department)"
Write-Host "Confidence:             $($decision.confidence)"
Write-Host "Routing Score:          $($decision.score)"
Write-Host "Score Margin:           $($decision.margin)"
Write-Host ""
Write-Host "Reason:"
Write-Host $decision.reason
Write-Host ""

if ($decision.matched_keywords.Count -gt 0) {
    Write-Host "Matched keywords:"
    foreach ($keyword in $decision.matched_keywords) {
        Write-Host "  - $keyword"
    }
    Write-Host ""
}

if ($ShowScores) {
    Write-Host "Complete agent scores:" -ForegroundColor Cyan

    $scores |
        Select-Object agent, department, score |
        Format-Table -AutoSize

    foreach ($scoreEntry in $scores) {
        if ($scoreEntry.score -gt 0) {
            Write-Host "$($scoreEntry.agent) match details:"

            foreach ($detail in $scoreEntry.match_details) {
                Write-Host "  - $detail"
            }

            Write-Host ""
        }
    }
}

# ------------------------------------------------------------
# Recommendation-only mode
# ------------------------------------------------------------

if (-not $Apply) {
    Write-Host "No changes were made." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To apply this recommendation, run:"
    Write-Host (
        "powershell -ExecutionPolicy Bypass -File " +
        ".\scripts\tasks\Route-AIOfficeTask.ps1 " +
        "-TaskId `"$TaskId`" -Apply"
    )
    exit 0
}

# ------------------------------------------------------------
# Approval checks
# ------------------------------------------------------------

$existingAgent = Get-SafeText $task.assigned_agent

if (
    $policy.rules.preserve_existing_assignment_without_force -and
    -not [string]::IsNullOrWhiteSpace($existingAgent) -and
    $existingAgent -ne "chief-of-staff" -and
    $existingAgent -ne $decision.agent -and
    -not $Force
) {
    throw (
        "Task already has a specialist assignment: {0}. " +
        "Use -Force to replace it." -f
        $existingAgent
    )
}

if (
    $decision.confidence -eq "low" -and
    $policy.rules.require_force_for_low_confidence -and
    -not $Force
) {
    throw (
        "Routing confidence is low. Review the recommendation and " +
        "use -Force to apply it."
    )
}

if (
    $decision.confidence -eq "mixed" -and
    $decision.agent -ne "chief-of-staff" -and
    -not $Force
) {
    throw "Mixed routing decisions require Chief of Staff review."
}

# ------------------------------------------------------------
# Apply decision
# ------------------------------------------------------------

$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$previousAgent = Get-SafeText $task.assigned_agent
$previousDepartment = Get-SafeText $task.lead_department

$task.assigned_agent = $decision.agent
$task.lead_department = $decision.department
$task.updated_at = $timestamp

if ($policy.rules.record_routing_history) {
    $routingDetails = (
        "Routed from agent '{0}' and department '{1}' " +
        "to agent '{2}' and department '{3}'. " +
        "Confidence: {4}. Score: {5}. Margin: {6}. " +
        "Matched keywords: {7}" -f
        $previousAgent,
        $previousDepartment,
        $decision.agent,
        $decision.department,
        $decision.confidence,
        $decision.score,
        $decision.margin,
        ($decision.matched_keywords -join ", ")
    )

    $historyItems = @($task.history)

    $historyItems += [PSCustomObject]@{
        timestamp = $timestamp
        action = "task-routed"
        actor = "chief-of-staff-routing-engine"
        details = $routingDetails
    }

    $task.history = $historyItems
}

$task |
    ConvertTo-Json -Depth 15 |
    Set-Content `
        -LiteralPath $taskJsonPath `
        -Encoding UTF8

# ------------------------------------------------------------
# Update task register
# ------------------------------------------------------------

$register = Get-Content `
    -LiteralPath $taskRegisterPath `
    -Raw |
    ConvertFrom-Json

$registerUpdated = $false

foreach ($registerTask in @($register.tasks)) {
    if ($registerTask.task_id -eq $TaskId) {
        $registerTask.assigned_agent = $decision.agent
        $registerTask.lead_department = $decision.department
        $registerTask.updated_at = $timestamp
        $registerUpdated = $true
    }
}

if (-not $registerUpdated) {
    Write-Host (
        "Warning: Task was updated, but no matching task-register entry was found."
    ) -ForegroundColor Yellow
}

$register.updated_at = $timestamp

$register |
    ConvertTo-Json -Depth 15 |
    Set-Content `
        -LiteralPath $taskRegisterPath `
        -Encoding UTF8

Write-Host ""
Write-Host "Routing decision applied successfully." -ForegroundColor Green
Write-Host "Assigned agent: $($decision.agent)"
Write-Host "Lead department: $($decision.department)"
Write-Host ""
