# Review Checklists

Detailed per-section checklists for the plan-review skill. Reference these during each section of the review.

---

## Architecture & System Design

- **Component boundaries** — Are responsibilities clearly separated? Does each module/service own a single concern?
- **Dependency analysis** — Map both explicit imports and implicit dependencies (shared state, event ordering, database triggers). Flag circular or hidden dependencies.
- **Coupling** — Are components loosely coupled? Can one change without cascading updates? Watch for tight coupling through shared data structures or God objects.
- **Database impact** — Schema changes: are migrations reversible? Indexing: will new queries hit indexes? Data volume: does the change handle tables with millions of rows? Lock contention during migrations?
- **Security architecture** — Authentication: is auth checked on all new endpoints? Authorization: are permission boundaries correct? Data exposure: does the API return more than the client needs? Input validation: are all external inputs sanitized?
- **Single points of failure** — Does the change introduce new SPOFs? Are there fallback paths for critical operations?
- **API contract compatibility** — Are existing API consumers affected? Is the change backwards-compatible? Are breaking changes versioned?

---

## Code Quality & Patterns

- **DRY assessment** — Is there real, meaningful duplication? (Not superficial similarity — actual copy-paste logic that will drift.)
- **Naming** — Do names communicate intent? Are they consistent with the existing codebase? Avoid abbreviations unless they're universal (e.g., `id`, `url`).
- **Abstraction levels** — Is each function operating at one level of abstraction? Are there functions mixing high-level orchestration with low-level details?
- **Error handling** — Are errors caught at the right level? Do error messages help debugging? Are errors propagated or swallowed? Is there a consistent error handling pattern?
- **Complexity and nesting** — Flag deeply nested conditionals (3+ levels). Suggest early returns, guard clauses, or extraction into named functions.
- **Conventions consistency** — Does the new code follow the patterns already established in the codebase? Check naming style, file organization, import ordering, comment style.
- **Constants and magic values** — Are literal values explained or extracted? Would a named constant improve readability?

---

## Testing Strategy

- **Coverage of new paths** — Every new code branch (if/else, switch case, error path) should have at least one test.
- **Edge cases** — Boundary values (0, 1, max, empty, null). Invalid input (wrong types, malformed data). Error conditions (network failure, timeout, permission denied). Concurrency (parallel requests, race conditions).
- **Test quality** — Tests should verify behavior, not implementation. Changing internals without changing behavior should not break tests. Avoid testing private methods directly.
- **Isolation** — Unit tests should not depend on external services, databases, or file systems. Use mocks/stubs for external dependencies.
- **Integration test gaps** — Are there flows that cross component boundaries without integration tests? Database transactions, API-to-service-to-DB paths, auth middleware chains.
- **Regression tests** — If this is a bug fix, is there a test that reproduces the original bug?
- **Test data** — Are test fixtures realistic? Do tests clean up after themselves? Are there shared fixtures that could cause test interference?

---

## Performance & Scalability

- **N+1 queries** — Does the code query inside a loop? Should it batch or use joins?
- **Pagination and bounded results** — Are list endpoints paginated? Are queries bounded? Could a large dataset cause unbounded memory usage?
- **Memory patterns** — Are large collections loaded entirely into memory? Could streaming or chunking be used?
- **Caching** — Are there repeated computations or queries that could be cached? If caching exists, is invalidation handled correctly?
- **Concurrency and race conditions** — Are shared resources protected? Could concurrent requests cause data corruption? Are database transactions used where needed?
- **Network round-trips** — Can multiple API calls be batched? Are there synchronous calls that could be parallelized?
- **Index usage** — Will new queries use existing indexes? Are new indexes needed? Will index maintenance impact write performance?
- **BIG CHANGE additions** — Horizontal scaling: does the change work across multiple instances? Bottlenecks under load: what breaks first at 10x traffic? Stateful vs stateless: does the change introduce server-local state?

---

## Risk, Gaps & Alternatives

- **Failure points** — What happens when each external dependency fails? Are there timeout/retry/circuit-breaker patterns?
- **Unhandled edge cases** — What inputs or states has the plan not considered?
- **Rollback strategy** — Can this change be reverted safely? Are database migrations reversible? Is there a feature flag for gradual rollout?
- **Migration risk** — Does the deployment require downtime? Is there a zero-downtime migration path? What happens if migration fails midway?
- **Gaps: error handling** — Are there code paths that don't handle errors?
- **Gaps: monitoring** — Will the team know if this feature breaks in production? Are there health checks, metrics, or alerts?
- **Gaps: documentation** — Are API changes documented? Are there runbooks for operational concerns?
- **Gaps: feature flags** — Should this be behind a feature flag for safe rollout?
- **BIG CHANGE additions** — Simpler alternatives: is there a fundamentally simpler approach that was not considered? Build vs buy: does a library/service already solve this? Impact on existing functionality: what existing features could break?
