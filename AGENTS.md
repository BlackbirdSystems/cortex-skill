# Cortex Memory Lifecycle

## Cortex Memory Policy

- Use the `cortex-memory` skill for any non-trivial task.
- Follow `skills/cortex-memory/references/workflow-policy.md` for the lifecycle rules.
- Follow `skills/cortex-memory/references/industry-recipes.md` for domain-specific extraction, linking, and durable-memory policy.
- If Cortex memory tools are unavailable, state the limitation and continue best-effort.

## Workflow Integration

This skill is automatically injected into your session context via lifecycle hooks. You do not need to manually include these instructions in your prompts; however, you MUST adhere to the graduation and traceability rules defined in the references.
