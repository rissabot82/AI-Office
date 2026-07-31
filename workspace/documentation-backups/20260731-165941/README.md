# AI Office

AI Office is a modular, local-first autonomous enterprise operating system powered by OpenClaw.

It coordinates executive planning, department work, long-term memory, autonomous workflows, human approvals, background workers, live execution, and operational reporting from a single extensible platform.

## Current Status

| Field | Current value |
|---|---|
| Current phase | Preparing Knowledge Graph and Reasoning |
| Current milestone | Core AI Office Platform Certified |
| Version | 1.4.0 |
| Release status | Operational |
| Next release | v1.5 Knowledge Graph and Reasoning |

## Operational Capabilities

- Executive Chief of Staff
- Department architecture and delegation
- Inter-department Message Bus
- Queue engine and routing
- Certified OpenClaw bridge
- Authenticated live execution
- Result normalization and artifact publishing
- Long-term memory
- Memory search, recall, context packets, health, and feedback
- Autonomous workflow goals, plans, and persistent runs
- Human approval gates
- Retry, checkpoint, failure, and restart recovery
- Background worker cycles
- Monitoring and executive reporting
- Local AI Office dashboard
- Gateway token rotation utility

## Roadmap

Completed:

- v1.1 OpenClaw Bridge
- v1.2 Department Intelligence
- v1.3 Long-Term Memory
- v1.4 Autonomous Workflows

Planned:

- v1.5 Knowledge Graph and Reasoning
- v1.6 Multi-Agent Collaboration
- v1.7 Personal Financial Office
- v1.8 Business Incubator
- v2.0 Autonomous AI Enterprise
- Post-v2.0 Self-Hosting AI Office

Discord integration is planned as a mobile command and approval channel.

See [ROADMAP.md](ROADMAP.md), [VISION.md](VISION.md), and [PROJECT-STATUS.md](PROJECT-STATUS.md).

## Dashboard

```powershell
Set-Location "E:\AI\AI-Office"

powershell -ExecutionPolicy Bypass -File `
    ".\scripts\dashboard\Start-AIOfficeDashboard.ps1" `
    -OpenBrowser
```

Default address:

```text
http://127.0.0.1:18880/
```

## Repository Rule

Secrets and live tokens must not be committed.
