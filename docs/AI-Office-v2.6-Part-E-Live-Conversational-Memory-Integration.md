# AI Office v2.6 Part E - Live Conversational Memory Integration

Part E wires durable memory retrieval into the live conversational runtime.

## Behavior

For each conversational turn:

1. Build the existing conversation prompt.
2. Retrieve relevant durable memory for the current request and scope.
3. Assemble a bounded Part D memory context package.
4. Append that memory as reference-only context.
5. Run the existing v2.5.1 quality-controlled inference pipeline.
6. Fall back to the memory-free prompt if memory retrieval or assembly fails.

## Safety

- Existing v2.5.1 output sanitization remains active.
- Memory context is reference material, not instruction material.
- Memory IDs are not intended for user-facing output.
- A memory-layer failure must not take down Discord or conversational execution.
