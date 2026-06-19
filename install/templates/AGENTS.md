# >>> cortex memory startup block >>>

## Cortex Memory Policy

- Use the `cortex-memory` skill for any non-trivial task.
- **CRITICAL**: You MUST NEVER bypass `cortex_search` (L1) or `semantic_search` (L2) to access the filesystem (L3) directly.
- **CRITICAL**: There is no "Lightweight Path". Any task requiring filesystem access or command execution MUST begin with `cortex_begin_task`.
- Follow `skills/cortex-memory/references/workflow-policy.md` for the lifecycle rules.
- Follow `skills/cortex-memory/references/industry-recipes.md` for domain-specific extraction, linking, and durable-memory policy.
- If Cortex memory tools are unavailable, state the limitation and continue best-effort.

## Workflow Integration

This skill is automatically injected into your session context via lifecycle hooks. You do not need to manually include these instructions in your prompts; however, you MUST adhere to the graduation and traceability rules defined in the references.

# <<< cortex memory startup block <<<
