#!/bin/bash

# Hook: UserPromptSubmit
# Purpose: Reinforce Cortex Memory Lifecycle on each user message

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "<before-task>\nFollow `skills/cortex-memory-lifecycle-hooks/references/workflow-policy.md` for lifecycle rules.\n</before-task>\n\n<during-task>\nIf the task is domain-specific, also follow `skills/cortex-memory-lifecycle-hooks/references/industry-recipes.md`.\n</during-task>\n\n<on-success>\nFollow the workflow policy for task closure.\n</on-success>"
  }
}
EOF
