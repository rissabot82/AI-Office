# AI Office v2.6 Part C - Memory Retrieval & Relevance

Part C adds deterministic memory retrieval and relevance scoring.

## Retrieval Signals

- title matches;
- content matches;
- tag matches;
- scope matches;
- memory-type matches;
- recency.

## Scope Safety

Cross-project retrieval remains disabled by default. When a scope is supplied, records from other scopes are excluded.

## Disabled Memories

Disabled records are never returned by normal retrieval.

## Live Runtime

Part C does not yet inject memory into live conversations. It establishes retrieval quality first so later integration can safely select only relevant context.
