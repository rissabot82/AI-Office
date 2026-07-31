# Multi-Agent Workflow Guide

Status: Active
Owner: Chief of Staff
Version: 1.0.0

## Purpose

The workflow engine coordinates multiple AI Office tasks as one project.

A workflow contains:

- A project objective
- A workflow owner
- Participating agents
- Child tasks
- Task dependencies
- Progress tracking
- Approval requirements
- A completion report

## Workflow Lifecycle

A typical workflow moves through:

1. planning
2. ready
3. active
4. review
5. approved
6. completed

A workflow may also become:

- blocked
- cancelled
- failed
- archived

## Creating a Workflow

Example:

powershell -ExecutionPolicy Bypass -File scripts/workflows/New-AIOfficeWorkflow.ps1 -Title "Elite Auto Sales Back-to-School Campaign" -Description "Plan and launch a complete dealership sales campaign." -Template dealership-campaign

## Adding Tasks

Example:

powershell -ExecutionPolicy Bypass -File scripts/workflows/Add-AIOfficeWorkflowTask.ps1 -WorkflowId WORKFLOW-20260730-0001 -Title "Develop campaign strategy" -Description "Define the campaign theme, offers, audiences, and channels." -Agent marketing -Department marketing -Sequence 1

## Dependencies

A task may depend on another workflow task.

Example:

powershell -ExecutionPolicy Bypass -File scripts/workflows/Add-AIOfficeWorkflowTask.ps1 -WorkflowId WORKFLOW-20260730-0001 -Title "Build campaign landing page" -Description "Create the campaign page after the strategy and creative are approved." -Agent website -Department website -DependsOn TASK-20260730-0002,TASK-20260730-0003 -Sequence 3

Dependencies must already be registered in the workflow.

## Optional Tasks

Add the Optional switch when a child task is useful but not required for workflow completion.

Example:

powershell -ExecutionPolicy Bypass -File scripts/workflows/Add-AIOfficeWorkflowTask.ps1 -WorkflowId WORKFLOW-20260730-0001 -Title "Develop alternate campaign concept" -Description "Create a backup concept." -Agent creative -Department creative -Optional

## Viewing a Workflow

Summary:

powershell -ExecutionPolicy Bypass -File scripts/workflows/Show-AIOfficeWorkflow.ps1 -WorkflowId WORKFLOW-20260730-0001

Detailed dependency view:

powershell -ExecutionPolicy Bypass -File scripts/workflows/Show-AIOfficeWorkflow.ps1 -WorkflowId WORKFLOW-20260730-0001 -Detailed

## Synchronizing Progress

The workflow record does not automatically update every time a task moves.

Run:

powershell -ExecutionPolicy Bypass -File scripts/workflows/Sync-AIOfficeWorkflow.ps1 -WorkflowId WORKFLOW-20260730-0001

This updates:

- Child task statuses
- Completed task count
- Blocked task count
- Progress percentage
- Overall workflow status

## Dependency Blocking

A task is considered dependency-blocked when one or more listed dependency tasks have not reached completed status.

Package 9 records this at the workflow level.

It does not automatically prevent the child task from being moved manually.

## Completing a Workflow

Normal completion requires:

- Every required child task to be completed
- Final workflow approval
- No missing required task records

Run:

powershell -ExecutionPolicy Bypass -File scripts/workflows/Complete-AIOfficeWorkflow.ps1 -WorkflowId WORKFLOW-20260730-0001

Use Force only after manually confirming all requirements:

powershell -ExecutionPolicy Bypass -File scripts/workflows/Complete-AIOfficeWorkflow.ps1 -WorkflowId WORKFLOW-20260730-0001 -Force -Notes "Completion manually authorized."

## Completion Report

Successful completion creates:

workspace/workflows/WORKFLOW-ID/reports/completion-report.md

## Workflow Folder

Each workflow contains:

workflow.json
plan.md
deliverables/
reports/

## Relationship to Tasks

Workflow tasks remain normal AI Office tasks.

They still support:

- Routing
- Movement
- Review
- Approval
- History
- Deliverables

The workflow record links those tasks into one coordinated project.

## Validation

Run:

powershell -ExecutionPolicy Bypass -File scripts/workflows/Test-AIOfficeWorkflows.ps1
