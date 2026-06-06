#!/usr/bin/env bash

# Hook: SessionStart
# Purpose: Remind Gemini about memory tools at session start

CONTEXT="<cortex-memory-reminder>
You are augmented with a memory layer provided by Cortex. Use it to preserve durable findings, decisions, failures, entities, and links without adding process noise.

## Immediate Activation
At the start of every session or when beginning a new significant task, you **MUST** call \`activate_skill\` with the name \`cortex-memory-lifecycle-hooks\` to ensure you have the latest specialized guidance and instructions for managing the memory cycle.

## L2 Synchronization
If the \`cortex-router\` tools (specifically \`semantic_list_documents\`) are available, you **MUST** call it once at the start of the session to gather current document checksums. Use this state to check if L1 durable memories (graduated from L2) require synchronization or invalidation due to source changes.

## Workflow Choice
- Follow \`skills/cortex-memory-lifecycle-hooks/references/workflow-policy.md\` for the lifecycle rules.
- Follow \`skills/cortex-memory-lifecycle-hooks/references/industry-recipes.md\` for domain-specific extraction, linking, and durable-memory policy.
</cortex-memory-reminder>"

# Output as JSON for the hook system
CONTEXT_JSON=$(echo "$CONTEXT" | python3 -c 'import json, sys; print(json.dumps(sys.stdin.read()))')
printf '{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": %s}}\n' "$CONTEXT_JSON"
