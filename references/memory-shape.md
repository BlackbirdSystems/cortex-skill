# Preferred Memory Shape

Use this shape for durable Cortex memories when the goal is later retrieval.

## Required Fields

- `summary`: short statement of the decision, insight, or finding
- `decision`: what was chosen, if applicable
- `references`: stable pointers to repo-relative files, commits, line numbers, tests, or evidence IDs
- `tests`: exact command(s) and outcome, if the memory is about implementation or validation
- `status`: `current`, `superseded`, or `rejected`

## Good Example

- Summary: `PgBouncer fronts runtime DB access; runtime DSN now hot-swaps from an encrypted bundle.`
- Decision: `Use a sealed bundle on the shared volume as the secret transport.`
- References: `go/main.go @ 75defab`, `docker-compose.yml @ 75defab`
- Tests: `just test` passed
- Status: `current`

## Bad Example

- Summary: copied a full config block
- References: missing
- Status: `current`

## Rules

- Prefer pointers over prose duplication.
- Do not copy large file contents into memory.
- Prefer repo-relative paths plus commit SHA over absolute filesystem paths.
- If a memory conflicts with the repository, trust the repository and mark the memory stale or superseded.
