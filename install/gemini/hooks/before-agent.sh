#!/bin/bash

# Hook: BeforeAgent
# Purpose: Inject memory workflow instructions into Gemini's context

CONTEXT="<cortex-memory>
## Workflow Choice

Follow \`skills/cortex-memory-lifecycle-hooks/references/workflow-policy.md\` for the lifecycle rules.

## Mandatory Search
You **MUST** call \`cortex.search\` and \`semantic_search\` before answering any substantive user questions to ensure multi-level (L1/L2) memory-augmented recall.

## Memory Reinforcement
When a memory is used to answer a question, you **MUST** call \`cortex.answer\` for \`answered_by\` links or \`cortex.verify\` for \`verified_by\` links. Use \`cortex.link\` only for other relationship types.

## Failures

If a failure teaches something reusable, capture it and link it using the workflow policy.
</cortex-memory>"

# Output as JSON for the hook system
CONTEXT_JSON=$(echo "$CONTEXT" | python3 -c 'import json, sys; print(json.dumps(sys.stdin.read()))')
printf '{"hookSpecificOutput": {"hookEventName": "BeforeAgent", "additionalContext": %s}}\n' "$CONTEXT_JSON"
