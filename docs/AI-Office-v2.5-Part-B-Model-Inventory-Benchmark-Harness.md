# AI Office v2.5 Part B — Local Model Inventory & Benchmark Harness

## Objective

Part B creates the repeatable measurement infrastructure needed before AI Office changes production model routing.

## Capabilities

- Discover installed Ollama models
- Persist model inventory snapshots
- Run one benchmark case against one model
- Run smoke tests across every installed model
- Run selected benchmark cases
- Run the complete v2.5 benchmark suite
- Capture model response text
- Capture elapsed execution time
- Persist benchmark results and run summaries

## Production Safety

Part B does **not** modify Discord routing, conversational routing, or the current production model selection.

The v2.4 runtime remains the production baseline while v2.5 gathers evidence.

## Smoke Validation

The Part B certification runs one minimal prompt against every installed model:

```text
Reply with exactly: BENCHMARK OK
```

This proves each discovered model can actually execute before deeper quality benchmarking begins.

## Full Benchmark

Part C will use this harness to run the full benchmark suite and evaluate response quality by task family.
