# Cortex Memory Workflow Policy

This file is the single source of truth for lifecycle behavior. Keep the skill, AGENTS template, and hook scripts pointed here instead of copying policy text into each surface.

## Task Declaration

A task is any goal-oriented work, directive, or operational action (e.g., "fix this bug," "deploy to production," "research this topic").

1. **Mandatory Declaration:** You MUST call `cortex.begin_task` before starting any actionable work.
2. **Context Retrieval:** Call `cortex.search` once at the start of any new task for relevant prior context.
3. **Extraction Configuration:** Call `cortex.configure_extraction` explicitly when recurring entities or named artifacts matter to the task goal.
4. **Active Linking:** Resolve recurring entities aggressively and link findings, decisions, evidence, failures, and outcomes while the context is fresh.
5. **Closure:** Call `cortex.finish_task` immediately when the work is complete or the goal is met.

## Exceptions (Ad-Hoc Queries)

Single-turn, ad-hoc queries where no ongoing goal is established do not require a formal `begin_task`.

1. **Mandatory Search:** You MUST call `cortex.search` before answering any substantive question to ensure the response is memory-augmented.
2. **Memory Reinforcement:** When a memory is used to answer a question, you MUST call `cortex.answer` for `answered_by` links or `cortex.verify` for `verified_by` links. Use `cortex.link` only for other relationship types.
3. **Mandatory Episode Logging:** Even without a declared task, any substantive discovery, command outcome, or procedural context MUST be logged as an `episode` memory using `cortex.store` or `cortex.put_memory`.
4. **Goal Promotion:** If an ad-hoc query evolves into a goal or actionable directive, you MUST immediately call `cortex.begin_task` before proceeding.
- **Examples:** Simple Q&A ("What does this acronym mean?"), status checks ("Is the database running?"), or read-only exploration that doesn't lead to a directive.

## Durable Memory

- Use `cortex.put_memory` or `cortex.store` for reusable findings, failures, or decisions.
- Prefer connected memories over isolated notes.
- Use `insight` for durable rules and invariants, `episode` for procedural context, and `summary` for compressed conclusions.

## On Errors

- If a failure teaches something reusable, capture it and link it to the affected artifact, evidence, or outcome.
- Search only when prior context could materially change the next step.

## Domain Routing

- Follow `references/industry-recipes.md` for domain-specific extraction, relationship, and durable-memory policy.
- Software engineering should use the software recipe to decide labels, links, and durable engineering memories.
