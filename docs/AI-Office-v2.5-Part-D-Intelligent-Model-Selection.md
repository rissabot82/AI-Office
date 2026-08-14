# AI Office v2.5 Part D — Intelligent Model Selection

## Objective

Part D turns the v2.5 benchmark results into a model-selection engine.

## Current Benchmarked Specialties

Based on the Part C baseline:

- General/default: `qwen2.5:3b`
- Conversation: `qwen2.5-coder:3b`
- Reasoning: `deepseek-r1:1.5b`
- Creative: `qwen2.5-coder:3b`
- Drafting: `qwen2.5:3b`
- Analysis: `qwen2.5:3b`
- Classification: `qwen2.5:3b`
- Coding: `qwen2.5-coder:3b`, but escalation remains recommended because all current local models scored below the coding target

## Selection Logic

AI Office now considers:

1. Task family
2. Required quality tier
3. Installed model availability
4. Benchmark family score
5. Required threshold
6. Escalation need

## Production Safety

Part D does not switch the live Discord or conversational runtime to intelligent selection.

That happens in Part E after this selector is certified independently.
