# AI Office v2.4 Part D — Department and Agent Routing

Part D routes Discord work into AI Office's departmental structure.

Default messages enter through the Chief of Staff. A single request can be explicitly routed with:

`/department <name> <request>`

Use `/departments` to list available routes.

The routing layer preserves the existing v2.3 conversational runtime while adding department context and routing metadata.
