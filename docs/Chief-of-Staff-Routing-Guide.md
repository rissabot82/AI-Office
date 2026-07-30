# Chief of Staff Routing Guide

Status: Active
Owner: Chief of Staff
Version: 1.0.0

## Purpose

The routing engine analyzes AI Office tasks and recommends the agent and department best suited to complete the work.

## Information Analyzed

The routing engine reviews:

- Task title
- Task description
- Tags
- Notes
- Configured routing keywords

## Scoring

Keyword matches receive different weights depending on where they appear.

A match in the title carries more weight than a match in general notes.

Multiword phrases receive a small additional bonus because they are usually more specific.

## Confidence Levels

### High

The leading agent has a strong score and a clear advantage over other agents.

### Medium

The leading agent has enough evidence to be a reasonable assignment.

### Low

The task contains limited evidence. Manual review or the Force option is required.

### Mixed

Multiple specialties are strongly represented or tied. The task should be coordinated by the Chief of Staff.

### None

No keywords matched. The Chief of Staff receives the task for manual classification.

## Recommendation Mode

The default command only recommends an assignment.

Example:

powershell -ExecutionPolicy Bypass -File scripts/tasks/Route-AIOfficeTask.ps1 -TaskId TASK-20260730-0001

This does not change the task.

## Displaying Scores

Use ShowScores to see how every agent scored.

Example:

powershell -ExecutionPolicy Bypass -File scripts/tasks/Route-AIOfficeTask.ps1 -TaskId TASK-20260730-0001 -ShowScores

## Applying a Recommendation

Use Apply to update the task.

Example:

powershell -ExecutionPolicy Bypass -File scripts/tasks/Route-AIOfficeTask.ps1 -TaskId TASK-20260730-0001 -Apply

The command updates:

- assigned_agent
- lead_department
- updated_at
- task history
- task register

## Force Option

Use Force only after reviewing the recommendation.

It may be needed when:

- Routing confidence is low
- A specialist was previously assigned
- You intentionally want to replace the current assignment

Example:

powershell -ExecutionPolicy Bypass -File scripts/tasks/Route-AIOfficeTask.ps1 -TaskId TASK-20260730-0001 -Apply -Force

## Mixed Tasks

Tasks involving several departments should normally be assigned to the Chief of Staff.

The Chief of Staff can then identify:

- Lead agent
- Supporting agents
- Required sequence
- Review requirements
- Final approval point

## Testing

Run:

powershell -ExecutionPolicy Bypass -File scripts/tasks/Test-AIOfficeRouting.ps1

The test checks:

- JSON validity
- Agent registration
- Routing rules
- Expected routing results

## Customization

Routing keywords are stored in:

config/tasks/routing-rules.json

Routing weights and confidence requirements are stored in:

config/tasks/routing-policy.json

Changes should be tested before being committed.
