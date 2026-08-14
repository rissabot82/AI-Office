# AI Office v2.6 Part G - Controlled Memory Capture

Part G adds an explicit, user-controlled durable-memory capture engine.

## Safety model
- Durable memory capture requires explicit user intent.
- Ordinary conversation is not automatically promoted to memory.
- Automatic inferred memory capture remains disabled.
- Existing durable-memory duplicate protections remain active.
- Part G does not silently alter the production conversation runtime.

## Supported explicit language
Examples include:
- Remember that ...
- Remember this ...
- Save this to memory ...
- Store this in memory ...

The final v2.6 release step can wire this certified capture engine into the live conversation runtime with rollback protection.
