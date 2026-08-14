# AI Office v2.4 Part H — Live Discord Activation and Certification

Part H closes the v2.4 Discord Mobile Operations build by adding an explicit live-activation gate.

The activation readiness check verifies:

- Discord bot token configuration
- Discord connection health
- allowlist configuration
- worker policy
- department routing policy
- safety/audit policy

Certification is intentionally structural and does not start the worker.

When the system is ready for live operation, `Enable-AIOfficeDiscordLiveOperations.ps1 -StartWorker` performs readiness checks before starting the Discord worker.

`Disable-AIOfficeDiscordLiveOperations.ps1` provides the controlled shutdown path.
