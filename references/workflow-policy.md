# Cortex Memory Workflow Policy

This file is the single source of truth for lifecycle behavior. Keep the skill, AGENTS template, and hook scripts pointed here instead of copying policy text into each surface.

## Retrieval Hierarchy & Graduation

Cortex operates using a multi-level retrieval strategy to maximize recall while maintaining accuracy. **If the `cortex-router` (L2 tools) is not available, L2 is skipped and L1 bridges directly to L3.**

1.  **L1: Cortex Memory (`cortex_search`):** Always check durable memory first.
2.  **L2: Semantic Search (`semantic_search`):** **(Optional)** If L1 is insufficient and `cortex-router` tools are available, use semantic search to bridge to project documentation and context.
3.  **L3: Filesystem (`glob`, `read_file`, `grep_search`):** Use the filesystem as the final source of truth.

**CRITICAL HIERARCHY RULE:** You MUST NEVER access the filesystem (L3) without first checking L1 (and L2, if available). There is no "Lightweight Path" that allows you to skip `cortex_search` or `cortex_begin_task` to save time. The filesystem should only be accessed if L1 and L2 are insufficient, or if the user explicitly provides an exact file path and requests you to only read it.

### Graduation Lifecycle (L2/L3 -> L1)
When valuable information is discovered via **L2 Semantic Search** or **L3 Filesystem Exploration**, it should be "graduated" to **L1 Durable Memory** if it meets any of the following criteria:
- **Durable Value:** The discovery represents a hard-won engineering rule, a design decision, or a recurring pattern that should survive across sessions.
- **Task Relevance:** The information is central to the current `begin_task` goal.
- **Sync Validation:** The source state has been validated using **checksums** (calculated locally by the client/agent using standard hashing tools or the hook script) to ensure the L1 memory is grounded in a verifiable version of the L2/L3 source.

**Graduation Action:**
- Call `cortex_store` to persist the validated finding as an `episode` or `insight`.
- **Mandatory Content:** The stored memory MUST include:
    - **Brief Summary:** A concise explanation of the finding.
    - **Source References:** Clear pointers to the originating filenames (e.g., `Source: docs/ARCHITECTURE.md`).
    - **Original Checksum:** You MUST store any references to docs or files as checksums in cortex (e.g., `Checksum: <sha256>`).
- **Linking:** Link the new L1 memory to the originating task or related artifacts.

## Staleness Management & Invalidation

To prevent L1 memory from becoming stale or invalid relative to the L2/L3 source of truth:

1. **Validation on Retrieval:** When an L1 memory with a `Source` reference and `Checksum` is retrieved via `cortex_search`, and the current task involves that source, you MUST:
    - Use **checksums + recency** to determine if the memory is out of date. If the information was pulled from L2 or external sources, attempt validation.
    - Perform a **Quick Validation** by comparing the stored `Original Checksum` against the current source state.
    - **Optimization:** If L2 tools (specifically `semantic_list_documents`) are available in your tool set, you MUST call it **once per session** (typically during the Priming phase) to gather the current state of documentation. Use this cached state for all validations in the same session.
    - If `semantic_list_documents` is not available, skip this optimization and fall back to **L3 (Filesystem)** checksum calculation for each validation.
    - **Conflict Resolution:** If the checksums do not match, **do NOT automatically invalidate**. You MUST ask the user which is the source of truth (the Cortex memory or the L2/L3 file) before taking invalidation or update action. Let the user decide.

2. **Proactive Conflict Detection:** Periodically run `cortex_insights` to identify contradictions between L1 memories and newly indexed L2 documentation.

3. **Invalidation Action:**
    - If a memory is found to be stale or incorrect, use `cortex_resolve_conflict` (if a newer version exists) or `cortex_set_visibility(hidden=true)` to archive the stale item.
    - Do NOT delete memories unless they are objectively false; archiving preserves the "journey" while removing noise from active retrieval.

## Task Declaration

A task is any goal-oriented work, directive, or operational action (e.g., "fix this bug," "deploy to production," "research this topic").

1. **Mandatory Declaration:** You MUST call `cortex_begin_task` before starting any actionable work.
2. **Context Retrieval:** Call `cortex_search` once at the start of any new task for relevant prior context.
3. **Extraction Configuration:** Call `cortex_configure_extraction` explicitly when recurring entities or named artifacts matter to the task goal.
4. **Active Linking:** Resolve recurring entities aggressively and link findings, decisions, evidence, failures, and outcomes while the context is fresh.
5. **Closure:** Call `cortex_finish_task` immediately when the work is complete or the goal is met.

## Exceptions (Ad-Hoc Queries)

Single-turn, ad-hoc queries where no ongoing goal is established do not require a formal `begin_task`.

1. **Mandatory Search:** You MUST call `cortex_search` before answering any substantive question to ensure the response is memory-augmented.
2. **Memory Reinforcement:** When a memory is used to answer a question, you MUST call `cortex_answer` for `answered_by` links or `cortex_verify` for `verified_by` links. Use `cortex_link` only for other relationship types.
3. **Mandatory Episode Logging:** Even without a declared task, any substantive discovery, command outcome, or procedural context MUST be logged as an `episode` memory using `cortex_store`.
4. **Goal Promotion:** If an ad-hoc query evolves into a goal or actionable directive, you MUST immediately call `cortex_begin_task` before proceeding.
5. **Filesystem Prohibition:** Ad-hoc queries do NOT permit jumping straight to the filesystem. If you need to read the filesystem (`read_file`, `glob`, etc.) or execute terminal commands, the task is **not** ad-hoc. You MUST call `cortex_begin_task`.
- **Examples:** Simple Q&A ("What does this acronym mean?"), status checks ("Is the database running?"), or read-only exploration that doesn't lead to a directive.

## Durable Memory

- Use `cortex_store` for reusable findings, failures, or decisions.
- Prefer connected memories over isolated notes.
- Use `insight` for durable rules and invariants, `episode` for procedural context, and `summary` for compressed conclusions.

## On Errors

- If a failure teaches something reusable, capture it and link it to the affected artifact, evidence, or outcome.
- Search only when prior context could materially change the next step.

## Domain Routing

- Follow `references/industry-recipes.md` for domain-specific extraction, relationship, and durable-memory policy.
- Software engineering should use the software recipe to decide labels, links, and durable engineering memories.
