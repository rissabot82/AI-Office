param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $Root

Write-Host ""
Write-Host "Testing AI Office v1.2 Part C Department Planning and Execution..." `
    -ForegroundColor Cyan
Write-Host ""

$Errors = New-Object System.Collections.Generic.List[string]

$JsonFiles = @(
    ".\config\departments\department-execution-policy.json",
    ".\config\departments\department-plan-schema.json",
    ".\config\departments\department-execution-schema.json",
    ".\workspace\templates\department-plan-template.json",
    ".\workspace\templates\department-execution-template.json"
)

foreach ($File in $JsonFiles) {
    try {
        Get-Content -LiteralPath $File -Raw |
            ConvertFrom-Json |
            Out-Null

        Write-Host "[VALID JSON] $File" -ForegroundColor Green
    }
    catch {
        Write-Host "[JSON ERROR] $File" -ForegroundColor Red
        $Errors.Add("Invalid JSON: " + $File)
    }
}

$Scripts = @(
    ".\scripts\departments\AIOfficeDepartmentExecution.Common.ps1",
    ".\scripts\departments\New-AIOfficeDepartmentPlan.ps1",
    ".\scripts\departments\New-AIOfficeDepartmentExecution.ps1",
    ".\scripts\departments\Send-AIOfficeDepartmentHandoff.ps1",
    ".\scripts\departments\Invoke-AIOfficeDepartmentExecution.ps1",
    ".\scripts\departments\Publish-AIOfficeDepartmentResult.ps1",
    ".\scripts\departments\Test-AIOfficeDepartmentExecution.ps1"
)

foreach ($Script in $Scripts) {
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
        Write-Host "[FOUND SCRIPT] $Script" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING    ] $Script" -ForegroundColor Red
        $Errors.Add("Missing script: " + $Script)
    }
}

$MessageId = ""
$WorkItemId = ""
$PlanId = ""
$ExecutionId = ""
$ResultMessageId = ""

try {
    $Message = & ".\scripts\messaging\New-AIOfficeMessage.ps1" `
        -From "chief-of-staff" `
        -To "marketing" `
        -MessageType "handoff" `
        -Priority "high" `
        -Subject "Create dealership campaign" `
        -ConversationTopic "DEPT-EXECUTION-TEST" `
        -Queue "outbox" `
        -PayloadJson '{"objective":"Create a dealership campaign plan.","deliverables":["Campaign strategy","Offer structure"],"required_capabilities":["campaign_strategy"],"risk_level":"low","approval_status":"not_required"}'

    $MessageId = [string]$Message.message_id

    $Inbox = @(
        & ".\scripts\departments\Invoke-AIOfficeDepartmentInbox.ps1" `
            -Department "marketing" `
            -Limit 1
    )

    $WorkItemId = [string]$Inbox[0].work_item_id

    $Plan = & ".\scripts\departments\New-AIOfficeDepartmentPlan.ps1" `
        -Department "marketing" `
        -WorkItemId $WorkItemId `
        -ExecutionMode "internal_reasoning"

    $PlanId = [string]$Plan.department_plan_id

    $Execution = & ".\scripts\departments\New-AIOfficeDepartmentExecution.ps1" `
        -Department "marketing" `
        -DepartmentPlanId $PlanId

    $ExecutionId = [string]$Execution.department_execution_id

    $Completed = & ".\scripts\departments\Invoke-AIOfficeDepartmentExecution.ps1" `
        -Department "marketing" `
        -DepartmentExecutionId $ExecutionId `
        -ResultSummary "Campaign planning completed successfully."

    if ([string]$Completed.status -ne "completed") {
        throw "Department execution did not complete."
    }

    Write-Host "[EXECUTION OK] $ExecutionId" `
        -ForegroundColor Green
}
catch {
    Write-Host "[EXECUTION ER] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Department execution failed: " + $_.Exception.Message)
}

try {
    $Published = & ".\scripts\departments\Publish-AIOfficeDepartmentResult.ps1" `
        -Department "marketing" `
        -DepartmentExecutionId $ExecutionId

    $ResultMessageId = [string]$Published.message_id

    if ([string]::IsNullOrWhiteSpace($ResultMessageId)) {
        throw "Department result was not published."
    }

    Write-Host "[RESULT OK  ] $ResultMessageId" `
        -ForegroundColor Green
}
catch {
    Write-Host "[RESULT ERR ] $($_.Exception.Message)" `
        -ForegroundColor Red
    $Errors.Add("Result publishing failed: " + $_.Exception.Message)
}

foreach ($Path in @(
    ".\workspace\departments\marketing\work\$WorkItemId.json",
    ".\workspace\departments\marketing\plans\$PlanId.json",
    ".\workspace\departments\marketing\execution\$ExecutionId.json"
)) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

Get-ChildItem `
    -LiteralPath ".\workspace\departments\marketing\results" `
    -Filter "DRS-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        $Record = Get-Content -LiteralPath $_.FullName -Raw |
            ConvertFrom-Json

        if ([string]$Record.department_execution_id -eq $ExecutionId) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

Get-ChildItem `
    -LiteralPath ".\workspace\departments\marketing\classifications" `
    -Filter "DCL-*.json" `
    -File `
    -ErrorAction SilentlyContinue |
    ForEach-Object {
        $Record = Get-Content -LiteralPath $_.FullName -Raw |
            ConvertFrom-Json

        if ([string]$Record.message_id -eq $MessageId) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

foreach ($Folder in @(
    ".\workspace\departments\marketing\processed-inbox",
    ".\workspace\departments\marketing\failed-inbox"
)) {
    $Path = Join-Path $Folder ($MessageId + ".json")

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Remove-Item -LiteralPath $Path -Force
    }
}

foreach ($CurrentMessageId in @($MessageId, $ResultMessageId)) {
    if ([string]::IsNullOrWhiteSpace($CurrentMessageId)) {
        continue
    }

    foreach ($Queue in @(
        "inbox",
        "outbox",
        "processing",
        "processed",
        "failed",
        "dead-letter",
        "archive"
    )) {
        $Path = ".\workspace\messages\$Queue\$CurrentMessageId.json"

        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            Remove-Item -LiteralPath $Path -Force
        }
    }
}

& ".\scripts\messaging\Update-AIOfficeMessageIndex.ps1" |
    Out-Null

& ".\scripts\departments\Update-AIOfficeDepartmentIndex.ps1" |
    Out-Null

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host (
        $Errors.Count.ToString() +
        " Department Planning and Execution error or errors were found."
    ) -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "All AI Office v1.2 Part C Department Planning and Execution checks passed." `
    -ForegroundColor Green
