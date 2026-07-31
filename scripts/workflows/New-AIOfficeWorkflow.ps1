param(
    [Parameter(Mandatory = $true)]
    [string]$Title,

    [Parameter(Mandatory = $true)]
    [string]$Description,

    [Parameter(Mandatory = $false)]
    [ValidateSet(
        "blank",
        "dealership-campaign",
        "website-project",
        "youtube-launch",
        "side-hustle-review"
    )]
    [string]$Template = "blank",

    [Parameter(Mandatory = $false)]
    [string]$OwnerAgent = "chief-of-staff",

    [Parameter(Mandatory = $false)]
    [string]$LeadDepartment = "executive",

    [Parameter(Mandatory = $false)]
    [string]$CreatedBy = "Clarissa",

    [Parameter(Mandatory = $false)]
    [string]$DueDate = "",

    [Parameter(Mandatory = $false)]
    [switch]$NoApproval
)

$ErrorActionPreference = "Stop"

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repositoryRoot

$workflowRoot = ".\workspace\workflows"

if (-not (Test-Path -LiteralPath $workflowRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $workflowRoot -Force | Out-Null
}

$today = Get-Date -Format "yyyyMMdd"
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

$existingFolders = Get-ChildItem `
    -LiteralPath $workflowRoot `
    -Directory `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -match "^WORKFLOW-$today-(\d{4})$"
    }

$highestNumber = 0

foreach ($folder in $existingFolders) {
    if ($folder.Name -match "^WORKFLOW-$today-(\d{4})$") {
        $number = [int]$Matches[1]

        if ($number -gt $highestNumber) {
            $highestNumber = $number
        }
    }
}

$workflowId = "WORKFLOW-$today-{0:D4}" -f ($highestNumber + 1)
$workflowFolder = Join-Path $workflowRoot $workflowId

New-Item `
    -ItemType Directory `
    -Path $workflowFolder `
    -Force |
    Out-Null

if ([string]::IsNullOrWhiteSpace($DueDate)) {
    $dueDateValue = $null
}
else {
    try {
        $dueDateValue = (
            [datetime]::Parse($DueDate)
        ).ToString("yyyy-MM-dd")
    }
    catch {
        throw "DueDate must be a recognizable date."
    }
}

$approvalRequired = -not $NoApproval.IsPresent

if ($approvalRequired) {
    $approvalStatus = "pending"
}
else {
    $approvalStatus = "not-required"
}

$workflow = [ordered]@{
    workflow_id = $workflowId
    title = $Title
    description = $Description
    status = "planning"
    template = $Template
    owner_agent = $OwnerAgent
    lead_department = $LeadDepartment
    created_by = $CreatedBy
    created_at = $timestamp
    updated_at = $timestamp
    due_date = $dueDateValue
    approval_required = $approvalRequired
    approval_status = $approvalStatus
    progress = [ordered]@{
        total_tasks = 0
        completed_tasks = 0
        blocked_tasks = 0
        percentage = 0
    }
    tasks = @()
    deliverables = @()
    notes = @()
    history = @(
        [ordered]@{
            timestamp = $timestamp
            action = "workflow-created"
            actor = $CreatedBy
            details = "Workflow created using the $Template template."
        }
    )
}

$workflowPath = Join-Path $workflowFolder "workflow.json"

$workflow |
    ConvertTo-Json -Depth 20 |
    Set-Content `
        -LiteralPath $workflowPath `
        -Encoding UTF8

$planTemplatePath = ".\workspace\templates\workflow-plan-template.md"
$planPath = Join-Path $workflowFolder "plan.md"

$planContent = Get-Content `
    -LiteralPath $planTemplatePath `
    -Raw

$planContent = $planContent.Replace(
    "WORKFLOW-YYYYMMDD-0001",
    $workflowId
)

$planContent = $planContent.Replace(
    "Describe the final outcome this workflow must produce.",
    $Description
)

Set-Content `
    -LiteralPath $planPath `
    -Value $planContent `
    -Encoding UTF8

New-Item `
    -ItemType Directory `
    -Path (Join-Path $workflowFolder "deliverables") `
    -Force |
    Out-Null

New-Item `
    -ItemType Directory `
    -Path (Join-Path $workflowFolder "reports") `
    -Force |
    Out-Null

Write-Host ""
Write-Host "Workflow created successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Workflow ID: $workflowId"
Write-Host "Title:       $Title"
Write-Host "Template:    $Template"
Write-Host "Owner:       $OwnerAgent"
Write-Host "Folder:      $workflowFolder"
Write-Host ""
Write-Host "Next command:"
Write-Host (
    "powershell -ExecutionPolicy Bypass -File " +
    ".\scripts\workflows\Add-AIOfficeWorkflowTask.ps1 " +
    "-WorkflowId `"$workflowId`" " +
    "-Title `"First workflow task`" " +
    "-Description `"Describe the work.`" " +
    "-Agent `"chief-of-staff`" " +
    "-Department `"executive`""
)
