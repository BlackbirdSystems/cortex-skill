#!/bin/bash

# Hook: SessionStart
# Purpose: Inject Cortex Memory Lifecycle instructions at session start

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<before-task>\nFollow `skills/cortex-memory-lifecycle-hooks/references/workflow-policy.md` for lifecycle rules.\nIf the task is domain-specific, also follow `skills/cortex-memory-lifecycle-hooks/references/industry-recipes.md`.\n</before-task>\n\n<on-error>\nFollow the workflow policy for reusable failures.\n</on-error>\n\n<on-success>\nFollow the workflow policy for task closure.\n</on-success>"
  }
}
EOF
