# Knowledge Base Standards

## Purpose

These standards define how AI Office knowledge is recorded, maintained, and retired.

## File Naming

Use lowercase file names separated by hyphens.

Good examples:

- elite-auto-sales.md
- google-ads-conversion-rules.md
- july-2026-kia-offers.md

Avoid vague names such as:

- notes.md
- stuff.md
- new-document.md
- final-final-2.md

## Recommended Document Header

Every important knowledge document should begin with:

- Title
- Status
- Owner
- Last Reviewed
- Source

## Status Values

- Draft
- Active
- Needs Review
- Superseded
- Archived

## Knowledge Types

### Verified Fact

Information confirmed through a reliable source.

### User-Provided Fact

Information provided directly by the system owner.

### Inference

A conclusion derived from available evidence.

### Assumption

An unverified working belief.

### Decision

A documented project choice.

## Maintenance Rules

- Add dates to time-sensitive information.
- Include sources when available.
- Mark assumptions clearly.
- Review active records regularly.
- Archive outdated records.
- Link related records instead of duplicating them.
- Never place secrets in Markdown documents.

## Never Store

- Passwords
- API keys
- OAuth tokens
- Recovery codes
- Private keys
- Session cookies
- Full payment-card numbers
- Social Security numbers
- Authentication files
