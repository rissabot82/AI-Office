# AI Office Agents

## Purpose

The agents folder defines the specialized AI roles that operate within AI Office.

Each agent has a specific purpose, boundaries, capabilities, and approval requirements.

## Agent Structure

Each agent folder contains:

- AGENT.md: Human-readable operating instructions
- manifest.json: Machine-readable agent identity
- memory: Agent-specific reusable memory documentation
- prompts: Reusable prompt components
- tools: Approved tools and integration guidance
- workflows: Repeatable operating procedures

## Agents and Departments

Agents define how an AI role thinks and works.

Departments organize the projects, outputs, templates, reports, and business records produced by those agents.

## Shared Knowledge

Agents should consult the knowledge folder for reusable facts and reference information.

Agents should not create conflicting copies of shared knowledge inside their own folders.

## Human Authority

AI Office agents assist with decisions but do not replace the system owner's authority.

Actions with financial, legal, security, publishing, deletion, or external communication consequences require approval unless explicitly authorized.
