# AI Office Task Workflow Guide

Status: Active
Owner: Chief of Staff

## Purpose

The task system provides a consistent way to create, assign, review, approve, complete, and archive AI Office work.

## Standard Lifecycle

A normal task moves through these stages:

1. inbox
2. active
3. review
4. approved
5. outbox
6. completed
7. archived

A task may also become:

- blocked
- failed

## Creating a Task

Use the New-AIOfficeTask.ps1 script.

Example:

powershell -ExecutionPolicy Bypass -File scripts/tasks/New-AIOfficeTask.ps1 -Title "Create August campaign" -Description "Create the August dealership campaign plan." -Priority high -Agent marketing -Department marketing

## Viewing Tasks

Show all tasks:

powershell -ExecutionPolicy Bypass -File scripts/tasks/Show-AIOfficeTasks.ps1

Show active tasks:

powershell -ExecutionPolicy Bypass -File scripts/tasks/Show-AIOfficeTasks.ps1 -Status active

Show tasks assigned to Marketing:

powershell -ExecutionPolicy Bypass -File scripts/tasks/Show-AIOfficeTasks.ps1 -Agent marketing

## Moving a Task

Move a task into active work:

powershell -ExecutionPolicy Bypass -File scripts/tasks/Move-AIOfficeTask.ps1 -TaskId TASK-20260730-0001 -Status active

Move a task into review:

powershell -ExecutionPolicy Bypass -File scripts/tasks/Move-AIOfficeTask.ps1 -TaskId TASK-20260730-0001 -Status review

Complete a task:

powershell -ExecutionPolicy Bypass -File scripts/tasks/Move-AIOfficeTask.ps1 -TaskId TASK-20260730-0001 -Status completed

## Task Folder Contents

Each task folder contains:

- task.json
- brief.md

Additional deliverables may be placed in the same task folder.

## Human Approval

Tasks involving external communication, publishing, spending, account changes, deletion, or other consequential actions should retain approval_required as true.

## Git Policy

Operational task folders are ignored by Git according to the repository policy.

The task framework, scripts, schemas, and templates may be committed.

## Validation

Run:

powershell -ExecutionPolicy Bypass -File scripts/tasks/Test-AIOfficeTasks.ps1

This checks the task-system JSON files and existing task records.
