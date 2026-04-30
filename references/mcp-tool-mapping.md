# MCP Tool Mapping for Lifecycle Hooks

## Goal

Map every Cortex MCP tool to Priming, Synthesis, and Consolidation hooks so any complex process produces an auditable and linked memory trail.

## Lifecycle Coverage Matrix

| Tool | Primary Hook Stage | Why it Matters | Recommendation |
|---|---|---|---|
| `cortex.begin_task` | Priming | Enforced lifecycle entrypoint | Use for any complex process before substantive work. |
| `cortex.finish_task` | Consolidation | Enforced lifecycle exitpoint | Use to close the process, documenting outcomes and risks. |
| `cortex.store` | Synthesis | Canonical decision, discovery, failure, and durable-knowledge records | Use the routed domain recipe to decide whether to store `insight`, \`summary\`, or \`episode\`. Keep \`step_failure\` as an episodic record unless the domain recipe says otherwise. Store references, not copied file contents. |
| `cortex.put_memory` | Synthesis | Unified storage tool | Use for storing facts, decisions, evidence, and domain-specific durable knowledge when \`store\` is not otherwise required. Prefer source-of-truth pointers over mirrored content. |
| \`cortex.search\` | Priming / Synthesis / Consolidation | Context recall and verification | Run before each phase and once after closure to verify retrieval. Treat the repository as authoritative when a memory conflicts with a file reference. |
| \`cortex.search_memory\` | Priming / Synthesis / Consolidation | Semantic search | Use for broad context gathering across sessions. |
| \`cortex.get_memory\` | Synthesis / Consolidation | Verify specific knowledge nodes | Use before updating or referencing critical information. |
| \`cortex.link\` | Synthesis / Consolidation | Create knowledge traceability | Link evidence to discoveries and outcomes to decisions. |
| \`cortex.link_memories\` | Synthesis / Consolidation | Relationship management | Use to build a coherent graph of the journey. |
| \`cortex.insights\` | Synthesis / Consolidation | Conflict and redundancy detection | Run periodically in complex investigations to ensure health. If the user accepts or rejects a suggestion, log the outcome as a memory and link it to the originating insight. |
| \`cortex.get_memory_insights\`| Consolidation | Quality assurance | Identify contradictions that need resolution before closure. |
| \`cortex.get_evidence\` | Synthesis / Consolidation | Grounding and verification | Pull evidence IDs to support major claims or summaries. |
| \`cortex.summarize\` | Consolidation | Information compression | Trigger for long journeys to reduce noise for future retrieval. |
| \`cortex.set_visibility\` | Consolidation | Signal-to-noise management | Hide transient or low-signal debug memories after synthesis. |
| \`cortex.configure_extraction\`| Priming | Domain-specific entity mapping | Define what types of things (people, places, etc.) to track. |
| \`cortex.get_extraction_directives\`| Priming | Extraction policy alignment | Ensure you are extracting the right entities for the domain. |
| \`cortex.extract_entities\` | Synthesis | Entity discovery in notes | Automatically find graph-worthy entities in your findings. |
| \`cortex.resolve_entities\` | Priming / Synthesis | Identity management | Ensure \"John Doe\" in one note is the same \"John Doe\" in another. |
| \`cortex.resolve_conflict\` | Synthesis / Consolidation | Truth reconciliation | Merge or select between contradictory claims found via insights. |
| \`cortex.apply_graph_patch\` | Synthesis / Consolidation | Batched graph updates | Perform complex, atomic updates to the knowledge graph. |

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
