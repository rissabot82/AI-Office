# AI Office v2.4 Part G — Discord Safety and Audit

Part G adds the security/audit layer for the Discord interface.

It includes allowlist enforcement status, persistent audit events, token-like value redaction, security status reporting, and local command handlers for `/security` and `/audit`.

The certification test writes one temporary audit event, verifies redaction, then removes the test record.
