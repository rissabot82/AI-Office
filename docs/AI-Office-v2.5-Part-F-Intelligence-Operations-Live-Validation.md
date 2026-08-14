# AI Office v2.5 Part F — Intelligence Operations & Live Validation

## Objective

Part F verifies that the intelligence selector is not merely installed but is actually being used by the live conversational runtime.

## Capabilities

- Track recent model selections
- Track task-family usage
- Track fallback usage
- Track escalation recommendations
- Run live conversational validation across multiple task families
- Confirm Discord and self-hosting health remain operational

## Validation Matrix

The Part F certification runs live conversational turns for:

- Conversation
- Reasoning
- Creative
- Drafting
- Coding

Each validation checks the selected task family, selected model, response availability, fallback behavior, and escalation metadata.

## Expected Local Routing

- Conversation → qwen2.5-coder:3b
- Reasoning → deepseek-r1:1.5b
- Creative → qwen2.5-coder:3b
- Drafting → qwen2.5:3b
- Coding → qwen2.5-coder:3b with escalation recommended

Part F does not yet perform cloud escalation. That remains a later intelligence step.
