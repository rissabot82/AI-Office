# Quality Review and Approval Guide

Status: Active
Owner: Chief of Staff
Version: 1.0.0

## Purpose

This system creates a formal review and approval record for AI Office work.

It separates:

- Work completion
- Quality review
- Human approval
- Final delivery

## Review Process

A normal task should move through:

1. active
2. review
3. approved
4. outbox
5. completed

## Review Command

Preview a review without saving:

powershell -ExecutionPolicy Bypass -File scripts/review/Review-AIOfficeTask.ps1 -TaskId TASK-20260730-0001

Save the review:

powershell -ExecutionPolicy Bypass -File scripts/review/Review-AIOfficeTask.ps1 -TaskId TASK-20260730-0001 -Apply

Confirm all manual review checks:

powershell -ExecutionPolicy Bypass -File scripts/review/Review-AIOfficeTask.ps1 -TaskId TASK-20260730-0001 -PassManualChecks -Recommendation approved -Apply

## Automatic Checks

The system checks:

- Valid task JSON
- Task identity
- Title
- Description
- Assigned agent
- Lead department
- Deliverables
- Completion criteria
- Approval status
- Workspace location

## Manual Checks

The reviewer confirms:

- Requested outcome
- Deliverables
- Constraints
- Facts
- Assumptions
- Security
- Privacy
- Approval boundaries
- Output location
- Limitations

## Issue Severity

### Info

Informational note with no score penalty.

### Minor

Small quality problem that may allow conditional approval.

### Major

Material problem that blocks normal approval.

### Critical

Serious problem involving invalid records, security, safety, or integrity.

## Approval Command

Approve a reviewed task:

powershell -ExecutionPolicy Bypass -File scripts/review/Approve-AIOfficeTask.ps1 -TaskId TASK-20260730-0001 -Decision approved

Return it for revision:

powershell -ExecutionPolicy Bypass -File scripts/review/Approve-AIOfficeTask.ps1 -TaskId TASK-20260730-0001 -Decision returned-for-revision -Notes "Complete the missing deliverables."

Reject it:

powershell -ExecutionPolicy Bypass -File scripts/review/Approve-AIOfficeTask.ps1 -TaskId TASK-20260730-0001 -Decision rejected

## Force Option

Force bypasses normal review protections.

Use it only after manually checking the task.

Example:

powershell -ExecutionPolicy Bypass -File scripts/review/Approve-AIOfficeTask.ps1 -TaskId TASK-20260730-0001 -Decision approved -Force

## Review History

Show saved reviews and approvals:

powershell -ExecutionPolicy Bypass -File scripts/review/Show-AIOfficeReview.ps1 -TaskId TASK-20260730-0001

## Workflow Movement

Review and approval records do not automatically move task folders.

Use Move-AIOfficeTask.ps1 after each decision.

Example:

powershell -ExecutionPolicy Bypass -File scripts/tasks/Move-AIOfficeTask.ps1 -TaskId TASK-20260730-0001 -Status review

After approval:

powershell -ExecutionPolicy Bypass -File scripts/tasks/Move-AIOfficeTask.ps1 -TaskId TASK-20260730-0001 -Status approved

## Validation

Run:

powershell -ExecutionPolicy Bypass -File scripts/review/Test-AIOfficeReview.ps1
