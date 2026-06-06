# MCP Tool Mapping for Lifecycle Hooks

## Goal

Map every Cortex MCP tool to Priming, Synthesis, and Consolidation hooks so any complex process produces an auditable and linked memory trail.

## Lifecycle Coverage Matrix

| Tool | Layer | Primary Hook Stage | Why it Matters | Recommendation |
|---|---|---|---|---|
| `cortex.begin_task` | **L1 (Core)** | Priming | Enforced lifecycle entrypoint | Use for any complex process before substantive work. |
| `cortex.finish_task` | **L1 (Core)** | Consolidation | Enforced lifecycle exitpoint | Use to close the process, documenting outcomes and risks. |
| `cortex.store` | **L1 (Core)** | Synthesis | Canonical durable knowledge | **L1 Storage.** Use to graduate L2 findings or store L1 procedural context. Use the routed domain recipe to decide whether to store `insight`, `summary`, or `episode`. **Always capture failures as episodic records** unless the domain recipe says otherwise. |
| `cortex.search` | **L1 (Core)** | Priming / Synthesis | Context recall (L1) | **L1 Retrieval.** Run before each phase to check durable findings and prior context. |
| `semantic_search` | **L2 (Router)** | Priming / Synthesis | Semantic search (L2) | **L2 Retrieval (Optional).** Use when L1 recall is insufficient to gather broad context from indexed documentation. Graduation to L1 is required for durable findings. |
| `semantic_index_content`| **L2 (Router)** | Synthesis / Consolidation| Doc Indexing | **L2 Maintenance (Optional).** Index new documentation or complex outcomes for L2 retrieval. |
| `semantic_list_documents`| **L2 (Router)** | Priming | Doc Discovery | **L2 Discovery (Optional).** Check available documentation and **validate L1 checksums**. Call **once per session** to cache state for Quick Validation. |
| `csv_query_dataset` | **L2 (Router)** | Synthesis | Structured Data Retrieval | **L2 Data (Optional).** Query ingested datasets for factual grounding. |
| `csv_list_datasets` | **L2 (Router)** | Priming | Data Discovery | **L2 Discovery (Optional).** Identify available structured datasets. |
| `csv_get_schema` | **L2 (Router)** | Priming | Data Schema Alignment | **L2 Schema (Optional).** Understand dataset structure before querying. |
| `request_upload_url` | **L2 (Router)** | Synthesis | Large File Ingestion | **L2 Ingestion (Optional).** Prepare for bulk data or documentation indexing. |
| `cortex.get_memory` | **L1 (Core)** | Synthesis / Consolidation | Verify specific knowledge nodes | Use before updating or referencing critical information. |
| `cortex.link` | **L1 (Core)** | Synthesis / Consolidation | Create knowledge traceability | Link evidence to discoveries and outcomes to decisions. |
| `cortex.traverse_entity` | **L1 (Core)** | Synthesis | Graph traversal | Explore the neighborhood of an entity. |
| `cortex.insights` | **L1 (Core)** | Synthesis / Consolidation | Conflict and redundancy detection | Run periodically in complex investigations to ensure health. |
| `cortex.get_memory_insights`| **L1 (Core)** | Consolidation | Quality assurance | Identify contradictions that need resolution before closure. |
| `cortex.get_evidence` | **L1 (Core)** | Synthesis / Consolidation | Grounding and verification | Pull evidence IDs to support major claims or summaries. |
| `cortex.summarize` | **L1 (Core)** | Consolidation | Information compression | Trigger for long journeys to reduce noise for future retrieval. |
| `cortex.set_visibility` | **L1 (Core)** | Consolidation | Signal-to-noise management | Hide transient or low-signal debug memories after synthesis. |
| `cortex.configure_extraction`| **L1 (Core)** | Priming | Domain-specific entity mapping | Define what types of things (people, places, etc.) to track. |
| `cortex.get_extraction_directives`| **L1 (Core)** | Priming | Extraction policy alignment | Ensure you are extracting the right entities for the domain. |
| `cortex.extract_entities` | **L1 (Core)** | Synthesis | Entity discovery in notes | Automatically find graph-worthy entities in your findings. |
| `cortex.resolve_entities` | **L1 (Core)** | Priming / Synthesis | Identity management | Ensure "John Doe" in one note is the same "John Doe" in another. |
| `cortex.resolve_conflict` | **L1 (Core)** | Synthesis / Consolidation | Truth reconciliation | Merge or select between contradictory claims found via insights. |
| `cortex.apply_graph_patch` | **L1 (Core)** | Synthesis / Consolidation | Batched graph updates | Perform complex, atomic updates to the knowledge graph. |

## Generalized Process Example

Use this flow for a journey such as **\"Research and plan a sustainable garden for a community center\"**:

1. **Priming**: \`begin_task\` (Goal: Sustainable garden; Constraints: Budget, Sunlight; Success: Planting plan).
2. **Synthesis (Discovery)**:
   - \`search\` for local climate data.
   - \`store\` soil test results with a link to the source file or report.
   - \`extract_entities\` for recommended plant species.
3. **Synthesis (Planning)**:
   - \`store\` layout decisions with file or commit references.
   - \`link\` specific plants to their required sunlight levels (evidence).
4. **Refinement**:
   - \`insights\` to check for conflicting plant care instructions.
   - \`summarize\` the research notes into a final planting guide.
5. **Consolidation**:
   - \`get_evidence\` for the final cost estimate.
   - \`finish_task\` (Outcome: Plan complete; Deliverables: Planting map; Next: Buy seeds).

## Suggestion Rejection Logging

When \`cortex.insights\` or another suggestion-producing tool surfaces a recommendation and the user rejects it:

1. Store a memory that records the rejected suggestion.
2. Include the reason for rejection if the user gives one.
3. Add tags such as \`suggestion_rejected\` and \`user_feedback\`.
4. Link the rejection memory back to the original insight, suggestion, or decision so the traceability graph preserves the outcome.

## Domain Routing Reminder

When a task belongs to a specific domain, the lifecycle skill should stay generic and defer domain-specific extraction, relationship, and durable-memory policy to the matching recipe in \`references/industry-recipes.md\`.

Examples:

- Software engineering: follow the Software Engineering recipe for durable engineering outcomes.
- Legal research: follow the Legal Research recipe for precedent and citation handling.
- Academic research: follow the Academic Research recipe for evidence synthesis and paper summaries.

## Outcome Consolidation Recommendation

For every journey, enforce two mandatory memories through the wrapper tools:

- \`hook=start\`: captures the \"Why\" and \"How\" (objective, constraints, planned phases).
- \`hook=finish\`: captures the \"What\" and \"Next\" (status, deliverables, evidence, risks).

Both reference the same \`task_key\` and \`task_run_id\` for perfect traceability.
