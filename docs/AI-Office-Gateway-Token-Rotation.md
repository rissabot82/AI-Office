# AI Office Gateway Token Rotation Utility

Run:

`powershell
Set-Location "E:\AI\AI-Office"

powershell -ExecutionPolicy Bypass -File 
    ".\scripts\utilities\Rotate-AIOfficeGatewayToken.ps1"
`

The utility:

- Backs up openclaw.json
- Generates a new 256-bit gateway token
- Updates only gateway.auth.token
- Restarts the OpenClaw gateway
- Waits for port 18789
- Updates the current process environment
- Verifies authenticated AI Office access
- Rolls back if verification fails
- Records a token-free audit entry
