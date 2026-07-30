# Agent Manifest Standard

## Purpose

Each agent contains a manifest.json file that provides a machine-readable description of the agent.

## Required Fields

- id
- name
- version
- status
- department
- purpose
- capabilities
- approval_required
- knowledge_paths
- workspace_paths

## Identifier Rules

Agent identifiers must:

- Use lowercase letters
- Use hyphens between words
- Match the agent folder name
- Remain stable after the agent is placed into use

## Versioning

Agent versions use semantic versioning:

- Major version: Breaking behavior change
- Minor version: New compatible capability
- Patch version: Correction or clarification

Initial agent versions begin at 1.0.0.

## Status Values

- draft
- active
- paused
- deprecated
- archived

## Approval Flag

The approval_required value indicates whether the agent's external or consequential actions require human approval.

This flag does not override the shared Agent Operating Standard.
