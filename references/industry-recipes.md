# Industry Recipes for Cortex Memory

This catalog contains "recipes" for specific industries and domains. Use these to configure extraction labels and relationship types at the start of a task.

## Domain Schema Matrix

| Industry / Domain | Extraction Labels (`configure_extraction`) | Primary Relations (`link`) |
|---|---|---|
| **Software Engineering** | Bug, Feature, Component, Commit, PR | `fixed_in`, `affects`, `implemented_by` |
| **Theological / Bible** | Verse, Chapter, Parable, Apostle, Theme | `referenced_in`, `fulfills`, `preached_by` |
| **Legal / Litigation** | Case, Statute, Judge, Court, Precedent | `cites`, `overrules`, `applied_in` |
| **Medical / Healthcare** | Symptom, Diagnosis, Drug, Dosage, LabResult | `indicates`, `treats`, `contradicts` |
| **Academic / Research** | Paper, Author, Citation, Dataset, Metric | `published_by`, `uses_data_from`, `critiques` |
| **Project Management** | Milestone, Risk, Stakeholder, Deliverable | `blocks`, `mitigates`, `owned_by` |

---

## Detailed Industry Recipes

### 1. Software Engineering
- **Context**: Used for hardening codebases, refactoring, or feature development.
- **Workflow**: 
  - Call `cortex.configure_extraction` early with the smallest label set that fits the task, typically drawn from `Bug`, `Feature`, `Component`, `Commit`, and `PR`.
  - Resolve recurring entities early: services, components, files, issues, PRs, migrations, incidents, and people when they materially affect the work.
  - Link memories as they are created instead of waiting until the end. At minimum, connect `finding -> evidence`, `decision -> artifact`, `fix -> regression`, and `issue -> PR/commit` when those relationships are known.
  - Store architectural decisions as standalone durable memories with links to the affected subsystem and source-of-truth artifacts.
- **Durable Memory Policy**:
  - Do not rely only on `begin_task` and `finish_task` for software work; store reusable engineering knowledge explicitly.
  - Use `memory_type='insight'` for standalone behavioral rules, regression causes, preserved invariants, compatibility rules, and service/API contracts.
  - Use `memory_type='summary'` for architectural conclusions that compress several findings or fixes.
  - Use `memory_type='episode'` for procedural context, attempted steps, command outcomes, and transient debugging notes.
  - For each non-trivial accepted review finding or implemented fix, store at least one durable memory in standalone form.
  - Include the affected subsystem or component in the memory content.
  - Keep memories reference-backed: point to file paths, line references, commit SHAs, command outputs, or evidence IDs instead of copying full file contents or large snippets.
  - Prefer tags such as `engineering_rule`, `regression`, `compatibility`, `behavior_invariant`, and `fix_rationale`.
  - Be aggressive about linking `review finding -> fix outcome -> affected subsystem/file` and `decision -> evidence -> outcome` so later retrieval does not depend on text search alone.
- **Retrieval Check**:
  - After code review or bugfix work, run `cortex.search` using the component or subsystem name plus terms such as `regression`, `invariant`, `compatibility`, `fix`, or `behavior` to verify the durable memory is retrievable.
  - Prefer retrieval results that resolve to source-of-truth artifacts; if a memory looks stale, re-check the repository instead of trusting copied content.
- **Examples**:
  - `ConflictService must honor EpisodeHideAfterSummary during explicit summarize operations.`
  - `GraphService.ensureInColdStore must copy the real item state from overlay/WARM and must not synthesize placeholder content for relation promotion.`
  - `MCP summarize availability must reflect local summarization support, not only OpenAI-backed summarization.`

### 2. Theological Study
- **Context**: Used for deep analysis of scripture or religious texts.
- **Workflow**:
  - `configure_extraction(labels="Verse, Theme, Apostle")`.
  - `link` a `Verse` (e.g., Romans 5:8) to a `Theme` (e.g., Grace).
  - Use `extract_entities` on commentaries to find cross-references.

### 3. Academic Research
- **Context**: Used for literature reviews and evidence synthesis.
- **Workflow**:
  - `configure_extraction(labels="Paper, Author, Methodology")`.
  - `link` a `Metric` (e.g., Accuracy) to the `Paper` that reported it.
  - `summarize` multiple papers into a single thematic insight.

### 4. Legal Research
- **Context**: Used for case law analysis and building legal arguments.
- **Workflow**:
  - `configure_extraction(labels="Case, Statute, Precedent")`.
  - `link` a `Case` to the `Statute` it interprets.
  - `insights` to find conflicting rulings across different courts.

---

## Adding New Recipes
To add a new industry recipe, append a new row to the **Domain Schema Matrix** and provide a brief **Detailed Industry Recipe** following the established format.
