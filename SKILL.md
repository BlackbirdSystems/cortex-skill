---
name: cortex-memory
description: Strict lifecycle logging and durable memory capture for all Cortex work. You MUST execute cortex_search (L1) and semantic_search (L2, if available) before accessing the filesystem (L3), and you MUST use cortex_begin_task before starting work that makes modifications.
---

# Cortex Memory

Strict lifecycle logging and durable memory capture for all Cortex work. You MUST execute cortex_search (L1) and semantic_search (L2, if available) before accessing the filesystem (L3), and you MUST use cortex_begin_task before starting work that makes modifications.

## Mandatory Retrieval Hierarchy
This skill enforces a multi-level retrieval strategy:
1. **L1 (Cortex):** Durable episodic memory. Always available.
2. **L2 (Semantic):** **(Optional)** Project documentation and indexed context (via `cortex-router`). If L2 tools are not available, the skill bridges directly from L1 to L3.
3. **L3 (Filesystem):** Local source of truth. Always available.

## Features
- **Cortex-Router Awareness:** Integrated lifecycle for structured data and semantic document search.
- **Graduation Lifecycle:** Formal process for graduating L2/L3 findings (semantic or filesystem) to L1 durable memory with mandatory source references (filenames/checksums) and brief summaries.
- **Staleness Management:** Active validation of L1 memories against L2/L3 sources of truth to prevent "knowledge decay."
- **Durable Traceability:** Automatically links findings, decisions, and outcomes.

The actual workflow lives in [references/workflow-policy.md](references/workflow-policy.md).

If the task is domain-specific, load only the matching recipe in [references/industry-recipes.md](references/industry-recipes.md).
