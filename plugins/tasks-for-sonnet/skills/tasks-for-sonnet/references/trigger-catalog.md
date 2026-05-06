# Trigger Catalog

Full IF/THEN trigger rules and stack examples referenced from `SKILL.md` § 3. Read this when:

- Writing a task whose acceptance criteria touch a boundary (server route, schema, AI/HTTP/RPC call, analytics, file upload, auth, migration).
- Acting as Auditor on a sprint diff and enumerating `triggers_satisfied: [{trigger_id, file, line}]`.
- Reviewing a plan that targets a junior implementation agent and you need to cite at least one trigger per boundary task.

The catalog is split into two layers: **Universal triggers** (concise, stack-agnostic patterns that apply almost everywhere) and the **Trigger catalog proper** (each entry promoted from a real defect class an external reviewer caught after the in-loop harness missed it).

**Lineage rule.** Every trigger here was promoted from a reviewer-caught defect class. **Do not delete a trigger** without first showing the underlying class extinct (≥ 2 sprints with zero recurrence) in the project's findings ledger. See SKILL.md § Skill Update Loop.

## Table of contents

- [Universal triggers (apply across stacks)](#universal-triggers-apply-across-stacks)
- [Trigger catalog](#trigger-catalog)
  - [Client-trust boundary](#client-trust-boundary)
  - [Schema bounds](#schema-bounds)
  - [State / enum drift (single source of truth)](#state--enum-drift-single-source-of-truth)
  - [Provider reliability](#provider-reliability)
  - [PII / privacy](#pii--privacy)
  - [Partial-vs-final lifecycle](#partial-vs-final-lifecycle)
  - [Live runtime path](#live-runtime-path)

## Universal triggers (apply across stacks)

```text
IF any button starts a fetch
THEN add a pre-state-update in-flight ref guard. `disabled` alone is not enough.

IF any image uses onLoad / onError visual state
THEN add an img.complete mount check. Cached images don't fire onLoad.

IF any env var is read in production-relevant code
THEN update env.example AND deployment docs. Grep mechanically:
     `grep -r "process\.env\[" <feature-dir>` count must match env.example count.

IF any numeric env parser is changed
THEN test 0, -1, NaN, "abc", "1abc", "1.5". `parseInt` accepts partials silently.

IF any AI / provider response is returned to client
THEN validate / normalize it before returning 200. Empty / whitespace / malformed
     must be rejected with telemetry.

IF any external call can hang
THEN add timeout (AbortController, ctx.WithTimeout, etc.) or document the
     platform timeout decision.
```

## Trigger catalog

These triggers were each promoted from a real catch where an external reviewer (typically Codex) caught something the in-loop harness missed. Each is stack-agnostic; examples illustrate.

### Client-trust boundary

```text
IF a request schema accepts role / createdAt / id / sessionToken / actorId
THEN OMIT the field from the request schema entirely; the server assigns it.
     Allowlisting is INSUFFICIENT — allowlisted role: 'assistant' still permits
     a forged trusted turn. Allowlisted createdAt still corrupts ordering.
     Test: send the field with a hostile value; assert the request is rejected
     OR the field is ignored and the server-assigned value is used.

IF a request schema accepts modelId / mimeType / providerHint / featureFlag
THEN allowlist server-side from a config / env constant array; reject anything
     not in the allowlist; never forward the client value to the provider as-is.
     For mimeType additionally: byte-level MIME sniff (e.g. `file-type`,
     `python-magic`, `mime-detective`) — the header is untrusted.
     Test: send a value not in the allowlist; assert 400 + canonical error code.
```

Stack examples:

- TypeScript / Zod: `z.object({ messages: z.array(...) /* role omitted */ })`
- Python / Pydantic: define `RequestModel` without `role`; assign in handler.
- Go: define request struct without the field; assign on the server side.
- Ruby / ActiveRecord: use `permitted_params` allowlist; never `params.permit!`.

### Schema bounds

```text
IF a string field is user-supplied content
THEN apply trim + min(1) + max(N) by default. Only relax with an explicit
     comment stating why empty / whitespace / oversize is acceptable.
     Test: empty, "   " (whitespace-only), and N+1-char inputs each rejected
     at parse time.

IF a number field is a count / duration / size
THEN apply integer + non-negative bounds (or explicit signed bounds with
     a one-line reason for negatives).
     Test: 0, -1, NaN, 1.5, "abc", "1abc" each rejected at parse time.
```

Stack examples:

- Zod: `z.string().trim().min(1).max(2000)`, `z.number().int().nonnegative()`
- Pydantic: `Field(min_length=1, max_length=2000, strip_whitespace=True)`, `conint(ge=0)`
- Joi: `Joi.string().trim().min(1).max(2000).required()`
- Rust / `validator`: `#[validate(length(min=1, max=2000))]`

### State / enum drift (single source of truth)

```text
IF a column is named status / role / state / kind / phase
THEN model it as a typed enum or CHECK constraint at the DB layer; never raw
     untyped string.
     Cross-check: every code path that sets the column uses a value from a
     single source-of-truth constant array exported from one module. Stub
     fixtures import from the same constant.
     Test: insert with an unknown literal must fail at the DB layer.
```

Stack examples:

- Postgres + Drizzle / Prisma: `pgEnum('status', [...] as const)`; export the array.
- Postgres + raw SQL / SQLAlchemy: `CHECK (status IN ('a','b','c'))` + Python `Enum`.
- MySQL: `ENUM('a','b','c')` column type.
- Application-only (no DB enum): one TypeScript const + a runtime parser.

### Provider reliability

```text
IF a route calls an external AI / HTTP / RPC provider
THEN wrap in a cancellation primitive with explicit timeout (default 30s);
     validate the response shape with the provider's schema;
     reject empty / whitespace-only payloads before returning success;
     emit a telemetry event on timeout / empty / shape-mismatch.
     Test: mock a provider that hangs (rejected via cancellation), returns ""
     (rejected), and returns malformed payload (rejected).
```

Stack examples:

- Node / fetch: `AbortController` + `AbortSignal.timeout(30_000)`.
- Python / httpx: `timeout=httpx.Timeout(30.0)` + Pydantic response model.
- Go: `context.WithTimeout` + struct unmarshal validation.
- Java / OkHttp: `callTimeout(Duration.ofSeconds(30))`.

### PII / privacy

```text
IF an analytics / logging event property is derived from user input
THEN the property name MUST be in an allowlist module (one source of truth);
     identifiers MUST be hashed (SHA-256 + project pepper from env), not raw.
     Forbidden raw: email, phone, IP, free-text answers, prompts, provider
     tokens, captcha tokens, distinct IDs derived from PII.
     If the allowlist module does not yet exist, create it as part of the
     same task — seed with [] and the forbidden-list comment.
     Test: snapshot test asserting the allowlist contents; unit test that the
     hash function actually hashes (input ≠ output, deterministic across runs).
```

Stack examples:

- TypeScript: `lib/analytics/allowed-properties.ts` exporting `as const` array.
- Python: `analytics/allowed_properties.py` with `Final[frozenset[str]] = frozenset({...})`.
- Java: enum class `AnalyticsProperty` with allowlist values.

### Partial-vs-final lifecycle

```text
IF a schema uses a partial / draft variant for an in-progress lifecycle
THEN a paired full / refinement schema MUST exist for the terminal boundary
     (e.g. complete / submit / finalize handler), and the contract MUST be
     stated in a one-line comment on both schemas.
     Test: terminal handler rejects payloads valid against the partial schema
     but missing required terminal fields (e.g. consent: true + email: undefined
     when consent implies email).
```

Stack examples:

- Zod: `BaseSchema` and `BaseSchema.partial()` paired with `BaseSchema.refine(...)` on the terminal route.
- Pydantic: `DraftModel` (all `Optional`) + `FinalModel` extending with `model_validator(mode='after')`.

### Live runtime path

Junior models routinely ship the new artefact (helper, schema, adapter, contract) and its unit tests, while leaving the live production path on the old wiring. The artefact passes; the runtime never reaches it. The fix is to require at least one test that fails when the runtime is unwired.

```text
IF a task adds a new abstraction, schema, adapter, helper, or contract
THEN at least one test MUST exercise the live production path through the
     public handler / route / component / entry point — not only the new
     artefact in isolation. The test MUST fail if the runtime still uses
     the old path or never reaches the new one. Unit tests on the artefact
     alone are necessary but not sufficient.
```

This is the meta-rule. The seven instantiations below all share its shape — each was promoted from a class of catch where the artefact was correct but the live path was untouched.

#### End-to-end wiring

```text
IF a task adds a new helper / utility / abstraction
THEN add at least one integration or E2E test through the public handler
     or component that would fail if the helper were unused. Importing the
     helper directly in tests is fine, but it does not prove the runtime
     calls it.
```

#### Old contract retirement

```text
IF the task replaces contract A with contract B (function rename, schema
   migration, type swap, endpoint replacement)
THEN acceptance criteria MUST prove all three:
     1. B is used by the runtime (positive runtime test).
     2. A is not used in any active runtime path (static check on old
        type / function / route / string names — `rg`/grep at minimum).
     3. Any remaining A usage is explicitly marked legacy or test-only
        with a one-line comment.
     Test: a deliberate dead-code injection of A in a runtime path fails
     CI. Static absence alone is necessary but not sufficient.
```

#### Prompt / schema / renderer lockstep

```text
IF an LLM call can return structured tool / UI / action data
THEN the task MUST update and test in lockstep:
     - the prompt that lists allowed tool / action names,
     - the schema that validates them and rejects unknown values,
     - the renderer / dispatcher that handles every allowed value,
     - one E2E test that takes a real returned value end-to-end —
       prompt → schema → renderer → submit / persist.
     Any of the four out of sync is a defect class, not a polish item.
```

#### Source-of-truth extraction

```text
IF the user selects, clicks, or otherwise picks a structured answer
THEN the application MUST write the stable canonical value to structured
     state (request body, persisted record, message metadata) before the
     next model call or downstream consumer runs.
     Test: inspect the next outbound request body or the persisted record
     — not the visible chat / UI text. "The model can infer it later" is
     the failure mode this rule prevents.
```

#### Spec completeness for input fields

```text
IF a task says "reduce typing", "provide ready answers", or otherwise
   adds structured-input affordances to a previously free-text surface
THEN every target field MUST declare its input kind explicitly:
     select / multi-select / text / amount / rating / confirm.
     For select-like fields, tests MUST assert the exact option values
     exist. "There is a list" is not a spec; the list contents are.
```

#### Negative-only checks insufficient

```text
IF a verification step uses `rg` / grep / static analysis to prove old
   code or old type names are gone
THEN it MUST be paired with a positive runtime test that fails if the
     replacement behaviour is absent. Absence-only checks cannot pass a
     migration task — they prove the old shape is not present, not that
     the new shape is reached.
```

#### Live path over unit path

```text
IF the task's tests import a helper / adapter / utility directly
THEN add at least one integration or E2E test through the public
     handler / component / route. The integration test MUST fail if
     the helper is unreferenced from the live path. Direct imports
     prove the artefact works in isolation; they do not prove the
     application uses it.
```

Stack examples (apply to whole family):

- TypeScript / React: integration test via `@testing-library` rendering the public component; assertion on outbound `fetch` mock body, not on visible text.
- Python / FastAPI: test client hits the public route; assertion on response shape and on a side-effect (DB row, queue message), not on the helper return value.
- Go / net/http: `httptest.NewServer` round-trip; assertion on response body and persistent state, with the old handler renamed to a sentinel that fails CI if reached.
- Rails / Rspec request specs: full request through the controller; assertion on rendered JSON and on a model attribute write, not on a helper-method return.
