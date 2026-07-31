# AI Office v1.1.2 Part A — Messaging Foundation

Part A installs the core communication contract for the AI Office Message Bus.

## Added

- Messaging policy
- Message JSON schema
- Routing policy
- Durable queue folders
- Message index
- Message template
- Common messaging library
- Message ID generation
- Correlation ID generation
- Conversation ID generation
- Message creation
- Identity integration
- Foundation validation

## Create a message

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\messaging\New-AIOfficeMessage.ps1" `
    -From "marketing" `
    -To "bridge" `
    -MessageType "execution_request" `
    -Subject "Create campaign assets" `
    -PayloadJson '{"workflow_id":"WF-1001","request":"Create assets"}'
```

## Show message status

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\messaging\Show-AIOfficeMessageStatus.ps1"
```

## Validate Part A

```powershell
powershell -ExecutionPolicy Bypass -File `
    ".\scripts\messaging\Test-AIOfficeMessagingFoundation.ps1"
```

Expected result:

```text
All AI Office v1.1.2 Part A Messaging Foundation checks passed.
```

## Next

Part B adds queue movement, routing, acknowledgement, and message retrieval.
