# Design: Hot Dog Finance MVP

## Readiness and scope

This is a proposed system design, not implementation evidence or blanket product approval. A shared online service is REQUIRED; offline storage is a per-device queue/cache, never a sync-free alternative. One configured Colombian family hot-dog business, Administrator/Operator, email/password, Spanish PWA, seven operation types (including approved operating expenses), and append-only history form the MVP. No inventory, formal accounting ledger, taxes, customers, invoices, split payments, multi-currency, business switching, or public onboarding.

Read [proposal](proposal.md), the four [access](specs/business-access/spec.md), [records](specs/financial-records/spec.md), [sync](specs/offline-financial-sync/spec.md), and [reporting/exchange](specs/financial-reporting-exchange/spec.md) specifications, then [tasks](tasks.md). Product decisions below block affected work, not all foundation work.

## Technical approach and boundaries

React 19 + TypeScript + Vite installable PWA; Dexie/IndexedDB local persistence; Supabase Auth/Postgres/RLS with authenticated Edge Function/RPC boundaries. This is the proposed stack; the offline/auth/storage proof and deployment costs are still unverified. Do not assume managed hosting automatically includes the required backup/PITR plan.

| Boundary | Responsibility |
|---|---|
| `apps/web/src/features/` | Spanish forms, routes, visible validation and sync states; never authoritative roles or totals |
| `packages/domain/src/` | Exact COP parsing, immutable snapshots, operation effects, report reducers and shared validation contracts |
| `apps/web/src/data/` | Session-partitioned Dexie documents/outbox/cache/cursor; atomic commits and version migration |
| `apps/web/src/sync/` | Frozen operations, retry/receipt resolution, paged pull and explicit attention |
| `supabase/migrations/`, `supabase/functions/sync/` | Tenant/role enforcement, transactional posting/corrections/imports, audit, receipts, commit-safe pull visibility |

```text
Spanish form -> exact validation -> Dexie transaction(document + outbox)
  -> freeze before first network attempt -> authenticated push -> RPC transaction
  -> facts + audit + receipt -> acknowledgement/local cache transaction
  <- authenticated paged pull -> Dexie transaction(facts + cursor)
```

## Exact money and quantities

`MoneyCop = bigint` represents whole COP, NOT centavos. JSON and database/API adapter boundaries use canonical base-10 integer decimal strings; never JSON numbers, floating-point multiplication, `parseFloat`, or lossy `Number` conversions for money. Spanish display separators are presentation only: a strict locale-aware UI parser produces the canonical value; API fields never accept currency symbols, grouping, exponent notation, whitespace, or decimal separators. Canonical signed form is `0` or an optional minus followed by a nonzero digit and digits; reject `+1`, `01`, `-0`, `1.0`, `1e3`, `NaN`, and unsupported precision, without silent rounding.

Use signed 64-bit persisted amounts, with exact range checks before storage: −9223372036854775808 through 9223372036854775807 COP. User-entered operation amounts, unit prices and costs must be positive; zero is allowed for observations/balances, signed values only for derived deltas/reversals and balances as permitted by D02. Validate line products, sums, inverse values and account deltas on browser AND server before committing; overflow rejects the complete operation, including reversal of an unrepresentable minimum. This representational limit is not a product spending limit. Aggregate calculations remain exact and reject unrepresentable persisted results.

Quantity is an exact positive decimal string. Approved D07 requires integer quantities for sales by unit; purchases measured by weight or volume allow up to three decimal places. Reject unsupported scale and any quantity × unit-price result containing fractional COP, without silent rounding. Shared fixtures must exercise minimum/maximum, sign, overflow, scale and localized input on both boundaries.

## Operation effects and reporting

Let `S`, `P`, `E`, `C`, `W` be signed accepted totals for sales, supplier purchases, operating expenses, contributions and withdrawals after linked inverse corrections. Purchases and expenses are paid spending in this MVP; no inventory valuation or cost-of-goods-sold inference. Expenses retain a description, amount and paying account, for example gas, transport or rent; they are not owner withdrawals and must not also be counted as purchases.

| Operation | Selected/source account | Destination account | Revenue | Purchase-based estimated cost |
|---|---:|---:|---:|---:|
| Sale | +amount (cash or bank) | — | +amount | 0 |
| Supplier purchase | −amount | — | 0 | +amount |
| Operating expense | −amount | — | 0 | 0 (separate expense total) |
| Owner contribution | +amount | — | 0 | 0 |
| Owner withdrawal | −amount | — | 0 | 0 |
| Cash → bank transfer | cash −amount | bank +amount | 0 | 0 |
| Bank → cash transfer | bank −amount | cash +amount | 0 | 0 |
| Reconciliation observation | 0 | 0 | 0 | 0 |

* **Estimated profit**: `S − P − E`, following approved D01; not formal accounting profit or inventory margin. Purchases and operating expenses remain distinct totals.
* **Cash flow**: period net cash+bank movement `S − P − E + C − W`. Internal transfers cancel in the combined total but remain visible per account. Contributions are not revenue/profit and withdrawals are not costs.
* **Available money**: Administrator-configured opening cash/bank balances with an effective start date, entered manually or imported, plus cumulative account deltas. Approved D02 allows negative balances with a visible warning, not rejection. No assumed real zero baseline; opening balances are not sales, profit or period cash flow, and importing them must not duplicate their effects.
* **Reconciliation difference**: observed − expected at a retained cutoff; never a posting or income/cost.

Confirmed reports reduce accepted facts once. Provisional device totals may overlay eligible queued operations by stable document/operation identity, explicitly labeled as local and incomplete across devices. Rejected/attention records are excluded; drafts are not posted money. On acknowledgement/pull replace the provisional representation with the accepted fact atomically, never count both. Example fixture (zero baseline is test setup, not policy): sale 36000, purchase 12000, operating expense 3000, contribution 10000, withdrawal 4000, cash→bank 8000 gives combined flow 27000 and estimated profit 21000; observation discrepancy −2000 changes neither.

Approved D03 uses America/Bogota and Monday-through-Sunday weeks. Linked correction effects are attributed to the original movement's reporting day; historical derived reports may change while immutable facts and retained reconciliation cutoffs do not. Store original occurrence instant, claimed client time, actual correction actor/time and server acceptance time separately; never use device timezone for report boundaries.

## Immutable correction and reconciliation

An accepted document never changes or disappears. A void appends a linked inverse of every original effect; a replacement appends that inverse plus a new validated snapshot in ONE server transaction with audit and receipt. Original + inverse net to zero; only the replacement contributes its new effects. Preserve original ID, correction group/target IDs, reason, correcting actor and timestamps. Approved D04 restricts posted corrections to active Administrators with a required reason; Operators may edit only their own drafts/never-sent records. Draft ownership never grants posted-correction authority; sale-price overrides do not automatically require a correction reason.

Serialize correction against the current target revision with uniqueness/locking: same operation replay returns its receipt; a different concurrent correction of the same already-corrected revision is rejected as attention, not a second inverse. Any failure rolls back inverse, replacement, audit and receipt together. Chained corrections target the current replacement explicitly. A denied edit/delete attempt is a distinct audit event, never a successful reversal; use sanitized metadata without retaining credentials or unsafe imported content. Offline synced-history edits stay denied.

Reconciliation retains account, period, observed amount/time, expected snapshot, difference, note when nonzero, actor and calculation basis (confirmed watermark plus included local operation IDs if provisional). Later arriving facts or corrections never mutate that snapshot invisibly: show the original cutoff and a separately labeled current comparison, or append a linked new observation. Reconciliation drafts may use optimistic version checks; finalized observations remain retained. Baseline/calendar decisions gate final behavior.

## Sync state, identity and transactions

UUIDv7 document/operation IDs and a canonical payload hash identify each operation. Define canonical serialization and schema version before hashing, including tenant, kind and payload. A unique `(business_id, operation_id)` binds the frozen hash to its receipt; same ID+hash returns the original outcome, mismatch rejects without posting. Authenticate before returning receipts; never leak another tenant's outcome.

| Internal state | Editable? | User-facing meaning |
|---|---|---|
| Local draft / never-sent queued | Creator only; replacement payload validated transactionally before first send | Guardado en este dispositivo / Pendiente de sincronizar |
| Possibly sent, outcome unknown | Frozen; same key, payload and hash only | Pendiente de sincronizar, confirmation pending |
| Accepted | No direct edits | Sincronizado; linked correction required |
| Permanent rejection / conflict | Original attempt retained; an explicit corrected new operation may follow definitive rejection | Requiere atención with reason |

Persist freeze BEFORE sending. A timeout is not rejection: resolve the same authenticated receipt or retry identical bytes until definitive outcome; never edit and assign a new identity while the first might have posted. Transient network/5xx/rate-limit failures retry with bounded backoff/jitter and manual retry. Authentication expiry pauses for reauthentication; role loss, invalid input, hash mismatch and version conflicts require attention. No automatic role-loss overwrite or retry storm. Mutable catalog/member/reconciliation drafts use base-version conflicts; immutable history uses linked correction, not last-write-wins.

Transaction boundaries:
1. Dexie document + outbox + optimistic projection commit together; only transaction completion permits “saved.” Quota, abort, unavailable storage or failed commit keeps the form and reports failure, never false success.
2. Server authorization/validation + immutable facts + account effects + audit + receipt commit together, per operation. Push transport batches are not implicitly atomic. No receipt can indicate success before commit.
3. Local acknowledgement and deduped accepted projection commit together. A crash can safely recover by identical retry/pull.
4. Each pull page and its cursor commit together. Failed local commit keeps the old cursor; restart/reapply is idempotent by fact ID/revision. Cursor is tenant/session scoped and supports deleted mutable metadata via retained change events.

Pull MUST expose only committed facts with a safe contiguous watermark. A naive allocated sequence/`MAX(sequence)` is NOT commit-order safe: transaction B may commit before lower-sequence A, causing A to be skipped. Proposed minimal strategy: serialize per-business change-number allocation under a transaction-held business lock; assign all transaction changes under that lock, commit before release, and publish only that committed watermark. Every writer (imports/corrections/catalog/access) follows this path. Snapshot paging must preserve transaction groups and never advance past unseen committed changes; prove delayed-A/committed-B and aborted-A cases with real DB transactions. Alternative mechanisms require equivalent proof before replacing this strategy.

Use a per-partition single replay leader/lease across tabs plus server idempotency for lease races and crashes. Tab coordination is optimization, not financial correctness. iOS retry triggers are launch, online/focus and **Sincronizar ahora**; no Background Sync guarantee.

## Offline shell, upgrades and storage limits

The minimal installable shell precedes offline E2E: manifest, versioned static assets, navigation fallback, persisted session/cache ownership and offline-readiness indicator after assets and database are usable. First authentication and initial tenant/cache bootstrap require online access. An uncached first visit cannot work offline.

Version local schema, payload protocol and server schema independently. Prefer additive server changes with a declared supported-client window; old unsupported clients receive upgrade-required without losing frozen outbox payloads. Migrations preserve IDs, receipts, hashes and unsent data; test interruption, old outbox replay and rollback compatibility. Never transform a possibly-sent payload into a different hash. An IndexedDB upgrade blocked by another tab shows a close/reload-other-tabs message; do not delete the database to unblock it.

Service workers cache allowlisted public static assets, not indiscriminate authenticated API responses or tokens. Activate a new worker only at a safe handoff with no in-flight local transaction and compatible schemas/outbox; notify the user before reload. Storage persistence requests are best effort. Browser eviction, private mode, quota exhaustion and sole-device loss can destroy unsent records: this remains an explicit LIMIT, not cloud recovery. Synced facts can be re-pulled after online auth; unsent facts cannot be reconstructed from server backups.

## Threat checklist

| Threat | Required control / evidence |
|---|---|
| Tenant or role bypass through RPC | RLS on every business table plus explicit RPC/Edge tenant, actor and current membership checks; least privilege; no service-role secret in client; direct-write and cross-tenant receipt/pull denial tests |
| Privileged DB functions bypass RLS | Restrict execution/search path, validate authenticated identity inside the transaction, deny unknown operation/version; test Operator against Admin-only access/catalog/import/reconciliation/export paths |
| Shared device/cache disclosure | Namespace local DB/cache/outbox by authenticated user + business; never show previous user's data; no local role as server authority; D05 gates offline expiry/logout/session UX |
| Revocation while disconnected | Server fails closed on reconnect; remote revocation cannot instantly invalidate an offline device; explain residual cached-data access and preserve quarantined unsent records |
| XSS/token exposure | Render imported/user text as text, safe validation messages, CSP/dependency review; never cache credentials in service-worker responses or log tokens |
| Malicious workbook/export | Limits before parsing, typed values, no formula execution, safe exports and per-row server authorization; see exchange specification |

Approved D05 permits offline use for at most 24 hours since the last online authorization validation, after online initial sign-in/bootstrap. Logout hides the partition without deleting unsent records; only the same user may recover it after reauthentication, and another user cannot see or replay it. Revocation records server time, actor and affected permission. On reconnect, unauthorized pending operations remain attention, excluded from balances/profit; client timestamps are evidence, never retroactive permission. An authorized active Administrator may explicitly approve incorporation after server validation, preserving the original author, source attempt and approving actor/time. Unknown outcomes must resolve before a new linked attempt; never mutate frozen possibly-sent payloads. Already accepted facts remain valid. No claim of encryption at rest or immediate offline revocation.

## Excel and recovery boundaries

Map → stage → typed validate → preview every row → explicit confirm → server revalidate/post → retain outcomes. Declare conservative tested workbook byte, sheet, row, column, cell-length and decompressed-content limits before enabling uploads; reject encrypted/macro-enabled/unrecognized files and formulas in mapped fields (never execute or trust cached formula results). Parse COP/date/quantity fields exactly, with explicit mapping formats rather than locale guessing. Exports encode untrusted text as text and neutralize spreadsheet-formula injection without changing numeric/date meaning; round-trip fixtures are required.

Persist batch identity, source metadata, stable source row identity and operation receipts. A workbook hash detects the identical file, NOT the same business row copied into another workbook. Prefer durable source record IDs; absent those, preview normalized-content candidate duplicates for explicit review, preserving legitimate identical sales. Approved D06 imports only explicitly selected valid rows, atomically per row, retaining visible error/duplicate reasons for unimported rows. Interrupted confirmation resumes original recorded outcomes, never reposting successful rows. This includes optional opening-balance imports under D02, distinct from ordinary transactions. No import bypasses normal validation/permissions or replaces stored history destructively.

Portable XLSX exports are record exchange, NOT a full database/Auth/schema/policy/receipt backup. Approved D09 sets a zero budget, daily backup objective, seven-day retention, a separate copy and Administrator responsibility for checking/downloading backups. RPO target is 24 hours of synchronized data, not a demonstrated guarantee; host/region and free-tier feasibility remain technical setup inputs requiring evidence. No paid resources or remote deployment is authorized. Pilot still requires a full isolated restore test plus export proof. Recovery fences writers, verifies backups and accounts for newer facts without overwriting history or device queues; use forward-compatible repair, never live resets or destructive down migrations.

## UX and evidence

[ui-design-system.html](ui-design-system.html) is a nonpersisting Spanish visual reference with whole-COP labels, price override, structured purchase snapshots, contribution/withdrawal and both transfer directions. Preserve semantic tokens, theme controls, visible focus, labels, error retention, reduced motion, keyboard tabs/dialog and text+icon sync states. No new account-management scope is implied.

Responsive targets: 360–430px mobile base, 48px controls; 600px two-column forms; 768px rail/two-column metrics; 1024px four-column metrics. Financial labels remain distinct; example totals are illustrative, not reconciled runtime evidence.

Existing `layout-evidence/375-dashboard-light.png`, `375-movements-dark.png`, `768-movements-light.png`, `1280-dashboard-dark.png` show foundations/components, despite their filenames. They are reference-only, NOT evidence of operational screens. Actual operational screen captures and viewport/keyboard/contrast checks are PENDING future acceptance under T6.1. No screenshots were recaptured in this review.

## Decision register

D01–D09 have recorded human approval. Exact conversation evidence is retained in the implementation logbook and project memory (D02–D09: observations 243–252). Approval unlocks the policy, not task completion, remote execution or pilot acceptance. A reopened OPEN policy still blocks its affected tasks. Dependencies and runtime proof remain required; D09 host/region and restoration are pending technical evidence.

| ID | Product choice and consequences | Status | Directly blocked tasks | Current safe scope |
|---|---|---|---|---|
| D01 | APPROVED: include operating expenses such as gas, transport and rent; profit = sales − purchases − expenses. Evidence: user selected “Incluir gastos operativos” when asked whether these expenses belong in MVP and reduce estimated profit | APPROVED | none | Seven operation types; expense records and report fixtures required in T3.1, T3.2, T3.4, T4.1, T4.4, T5.1–T5.3 and T6.1 |
| D02 | Administrator-configured cash/bank opening balances and start date, manual or imported; negative balances allowed with warnings; no opening sales/profit | APPROVED | T3.1, T4.3, T4.4 | Implement exact baseline/effects and guarded initial import; no assumed zero |
| D03 | America/Bogota; Monday week start; corrections affect original reporting day with actual correction audit retained | APPROVED | T3.3, T4.3, T4.4 | Implement exact calendar/report attribution and immutable cutoffs |
| D04 | Active Administrator only for posted void/replacement, required reason; Operator owns only never-sent drafts | APPROVED | T3.3, T4.2 | Server-enforced linked corrections; no hard edits |
| D05 | Online bootstrap; offline 24h; isolated retained logout queues; audited revocation and explicit Admin resolution, no timestamp-based authorization | APPROVED | T2.4 | Implement partition/session/attention policy after prerequisites |
| D06 | Preview then confirm selected valid rows, atomic per row with durable outcomes/resume; initial import included | APPROVED | T5.2 | Guarded per-row confirmation, no silent drop or destructive replace |
| D07 | Unit sales integer; weight/volume purchases up to three decimals; whole-COP products or reject | APPROVED | T3.1, T4.1, T5.1 | Shared exact quantity fixtures on both boundaries |
| D08 | Controlled first-Administrator provisioning; no public signup; secure credential setup, no plaintext credentials in source/chat | APPROVED | T2.3 | Implement controlled setup path; remote execution separately authorized |
| D09 | Zero budget; daily backups, seven-day retention, separate copy; Administrator owner, target RPO 24h synchronized data | APPROVED | T6.2 | Verify free host/region and restore feasibility before pilot; not a recovery guarantee |

## Verification and proposed files

Future implementation surfaces are `apps/web/`, `packages/domain/`, `supabase/`, `tests/`, root scripts/CI and `docs/operations.md`. None is created by this documentation review. Tests will cover exact arithmetic, DB RLS/RPC transactions, multi-tab/crash/offline replay, imports and accessible operational screens. Script interfaces and expected outcomes are defined in [tasks](tasks.md); no app tests, CI, restore, browser or viewport results have been observed here.
