# AI Office v2.5 Part G — Response Quality Control

Part G targets the response problems observed during early Discord testing.

It adds a live quality layer that:

- instructs the selected model to answer the user's actual request;
- prevents unnecessary internal routing/delegation narration;
- rejects exposed `ASSISTANT:`, `USER:`, and `SYSTEM:` prefixes;
- rejects known non-answer language;
- retries once with stronger instructions when an answer fails validation;
- preserves the v2.4 inference fallback if the quality-controlled local path fails.

This is intentionally a lightweight quality gate rather than a second LLM judge. It improves behavior without doubling inference cost on every request. A second inference occurs only when the first response fails deterministic quality checks.
