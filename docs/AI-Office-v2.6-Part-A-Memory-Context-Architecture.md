# AI Office v2.6 Part A - Memory & Context Architecture

Part A creates the durable memory architecture without changing the live v2.5.1 runtime.

Memory types:
- Project
- Dealership
- Organization
- Workflow
- User-approved

Safety:
- No secrets, tokens, or API keys
- Explicit approval required for sensitive memory
- Cross-project retrieval disabled by default
- Manual delete/disable supported

Memory retrieval is not live in Part A.
