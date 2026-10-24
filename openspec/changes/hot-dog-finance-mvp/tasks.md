# Tasks: Hot Dog Finance MVP

## Status and quick start

Implementation has been authorized. Current evidence and statuses are recorded below and in [the implementation logbook](../../../odd/tasks/finance-mvp.md); an unchecked task is not complete. Git exists with no commits at implementation start; the earlier no-Git observation is historical. Application checks remain PENDING until explicitly recorded. No CI approval or restore is claimed.

Read [proposal](proposal.md), [access](specs/business-access/spec.md), [records](specs/financial-records/spec.md), [sync](specs/offline-financial-sync/spec.md), [reporting/exchange](specs/financial-reporting-exchange/spec.md), and [design](design.md) before choosing work. P0 resolves workflow prerequisites and records product gates; it does NOT require all product choices to be settled before safe foundation starts. The [decision register](design.md#decision-register) is the single policy source.

## Review workload and branch chain

| Field | Forecast / rule |
|---|---|
| Prior 2400–3200 changed lines | Historical guess, not measured; insufficient evidence to keep as a bound |
| Current forecast | High risk of substantially exceeding that guess; app, DB, migrations, fixtures and browser tests are absent; numeric total unknown until scaffold/proof |
| Review budget | About 400 authored additions + deletions per child PR, about 60 minutes review; not a feature acceptance criterion |
| Delivery strategy | `auto-chain` (user selected) |
| Chain strategy | `feature-branch-chain` (user selected) |
| Integration/tracker | `develop`; future draft/no-merge tracker targets `main` |
| Work grouping | Six groups below; 23 implementation units plus P0, not six forced PRs |

Future chain: `main <- develop (draft tracker) <- 01-foundation-a <- 01-foundation-b <- 02-access-a <- ... <- 06-release-b`. First child targets `develop`; every later child branches from and targets its immediate predecessor, including across group boundaries. Merge reviewed children back through parents, integrate the first child into `develop`, then promote through the tracker only after release gates. Every child records start/end, dependencies, current-PR dependency diagram, follow-ups, out-of-scope, exact diff size, verification and rollback. No branch, commit or PR is created by this plan.

Each task is a cohesive candidate work unit with its fixtures/docs. On first implementation estimate each unit, then make ONE honest slicing pass into additional `-a/-b/...` child slices if needed; retain task IDs and assign proof per slice. Never compress code/tests to hit 400 lines. If no coherent split fits, report measured overage and request `size:exception`; do not silently approve it. Do not impose a six-slice ceiling.

## Check interface

T1.1/T1.2 established the root contracts below. Later task-specific suites remain future work. Use the same interface from the workspace root; named fixtures must execute rather than producing a zero-test success.

| Proposed command | Expected contract |
|---|---|
| `pnpm lint`, `pnpm format:check`, `pnpm typecheck`, `pnpm build` | No lint/format/type errors; production assets built |
| `pnpm test -- <suite>` | Named domain/client fixture suite executes and passes with test count |
| `pnpm test:db -- <suite>` | Isolated disposable Supabase/Postgres fixtures with real role and concurrent transaction assertions pass |
| `pnpm test:e2e -- <suite>` | Named browser/offline fixture passes against isolated seeded services |
| `pnpm check:plan` | Documentation links/IDs/gates/coverage verified; no runtime policy approval implied |
| `pnpm check:release` | Aggregates implemented checks plus observed/manual pilot evidence; missing evidence fails |

Do not use a database reset against pilot/production. DB fixtures may recreate ONLY named disposable test instances. Tests plus manual device/restore evidence are required where named; commands alone cannot prove those manual outcomes.

## Dependency and evidence convention

Every task below declares `Depends`, `Decisions`, `Surface`, `Spec`, `Accept`, `Check`, `Expected`, and `Rollback`. Depends are completion prerequisites; Decisions lists direct OPEN product blockers. Any OPEN direct blocker or blocked dependency prevents completion/shipping; safe preparatory fixtures must be explicitly labeled incomplete. `Decisions: none` does not bypass dependency gates.

For EACH task/slice, append this evidence record here when work actually occurs:

```text
Task/slice: <stable ID / child slice>
Status: UNSTARTED | BLOCKED | IN_PROGRESS | VERIFIED
Branch / parent / commit or PR: <observed identifiers, or absent>
Spec scenarios and decisions used: <exact heading, recorded choices>
Files changed / rollback boundary: <actual paths and data implications>
Command / environment / fixtures / count / exact result: <observed output>
Runtime/manual proof locator: <actual artifact, or PENDING and why>
Missing/failed proof / next unblocked step: <explicit>
```

No checkbox becomes complete until acceptance, named fixtures and evidence are observed. Never invent approval, CI PASS, receipts, dates or runtime results. Per-task default evidence: UNSTARTED, branch absent, commands NOT RUN, proof PENDING.

## P0 — workflow and product gate

- [x] **P0 — Establish safe starting boundary and decision routing**
  - Depends: none. Decisions: none (workflow-only gate; D01 is approved, D02–D09 still require individual human decisions).
  - Surface: this task file and [decision register](design.md#decision-register); future repository/tooling state read-only until separately authorized implementation setup.
  - Spec: all four specifications; [single-business boundary](specs/business-access/spec.md#requirement-single-business-membership-boundary).
  - Accept: record actual repository/scaffold state, authorized implementation setup and branch prerequisites, owner/status for each D01–D09. The historical Gentle AI 4.2.0 / missing `sdd-attempt` blocker is prior-session context, NOT rechecked here; future implementation must recheck its workflow prerequisites before execution, without assuming recovery. No unconditional “Decision needed before apply: No.”
  - Check: future `pnpm check:plan`; before scaffold, manual/read-only structural plan check with recorded result.
  - Expected: task graph and OPEN gates resolve; T1.1 is eligible only after workflow prerequisites; unresolved product choices still block exactly the tasks below.
  - Rollback: documentation-only state changes; preserve recorded choices/evidence and never initialize or reset a repository as part of this review.

## Group 1 — foundation and quality gates

- [x] **T1.1 — Create the smallest buildable workspace**
  - Depends: P0. Decisions: none.
  - Surface: future root `package.json`, workspace/lockfile, `apps/web/`, `packages/domain/`, TypeScript/Vite config.
  - Spec: [offline-ready shell](specs/offline-financial-sync/spec.md#requirement-offline-ready-shell-and-outbox-safe-upgrades), scenario “Reopen an initialized device offline” (scaffold prerequisite, not full offline acceptance).
  - Accept: React 19/TypeScript/Vite app builds, Spanish document language, empty domain package imports; no fabricated finance/auth behavior. Define root lint/format/typecheck/build contracts.
  - Check: `pnpm lint && pnpm format:check && pnpm typecheck && pnpm build` (future).
  - Expected: all four commands exit zero with production bundle; shell runtime still pending T2.2.
  - Rollback: remove only unused scaffold/config from this unit before data exists; no schema or user data reset.

- [ ] **T1.2 — Establish runnable isolated verification**
  - Depends: T1.1. Decisions: none.
  - Surface: future root scripts, Vitest/Playwright config, `tests/`, CI config and test prerequisites documentation.
  - Spec: [atomic persistence](specs/offline-financial-sync/spec.md#requirement-atomic-persistence-and-complete-pull); supports all later scenario checks.
  - Accept: define every script interface above, named-suite filtering, isolated DB startup/teardown and seeded identities. A deliberate failing fixture must fail its gate; zero selected tests must fail. CI runs the actual commands, no placeholder PASS.
  - Check: `pnpm test -- harness && pnpm test:db -- harness && pnpm test:e2e -- harness && pnpm check:plan` (future; intentional failure verified separately).
  - Expected: harness smoke suites execute with counts; missing infrastructure blocks instead of skipping financial tests silently.
  - Rollback: remove this unit's runner/CI wiring only; keep fixtures/docs alongside behavior they verify in later units.

## Group 2 — auth, tenancy and minimal offline shell

- [ ] **T2.1 — Enforce tenant and role foundation**
  - Depends: T1.2. Decisions: none.
  - Surface: future `supabase/migrations/`, `tests/db/access/`, auth adapters and typed contracts; synthetic identities only.
  - Spec: [Single-business membership boundary](specs/business-access/spec.md#requirement-single-business-membership-boundary), scenarios “Deny a boundary violation” and “Create a tenant member”.
  - Accept: tenant IDs from inception; individual memberships, Administrator/Operator constraints, last-active-Admin protection; RLS/direct RPC denies foreign tenants and Operator Admin actions on membership/access surfaces introduced in this task. Cross-tenant receipt probes are deferred to T3.2 when receipts/posting exist. No public signup flow or business switching.
  - Check: `pnpm test:db -- access` (future).
  - Expected: real-role cross-tenant membership/access reads/writes, Operator Admin actions and last-Admin removal fail with unchanged data on existing surfaces; permitted fixture succeeds. No authorization proof is claimed for future tables or nonexistent endpoints.
  - Rollback: disable new access UI/RPC exposure; use additive/forward repair migrations, never drop stored memberships/history.

- [ ] **T2.2 — Deliver minimal installable offline-capable shell**
  - Depends: T1.2. Decisions: none.
  - Surface: future `apps/web/` manifest, static assets, worker, route fallback/readiness UI; `tests/e2e/shell/`.
  - Spec: [Offline-ready shell](specs/offline-financial-sync/spec.md#requirement-offline-ready-shell-and-outbox-safe-upgrades), scenario “Reopen an initialized device offline” (static prerequisites).
  - Accept: warm shell reopens offline, cold uncached visit does not claim readiness; allowlist public static assets, no authenticated API/token caching; safe worker update notification and transaction handoff hook. Financial/auth offline access remains gated T2.4.
  - Check: `pnpm build && pnpm test:e2e -- shell` (future).
  - Expected: static offline navigation/install metadata and safe update fixtures pass before first financial offline E2E.
  - Rollback: disable worker registration/update feature compatibly; do not indiscriminately clear IndexedDB or private queues.

- [ ] **T2.3 — Implement first Admin and online access journeys**
  - Depends: T2.1, T2.2. Decisions: D08.
  - Surface: future `apps/web/src/features/auth/`, member UI/routes, controlled provisioning path, `tests/e2e/auth/`.
  - Spec: [Single-business membership boundary](specs/business-access/spec.md#requirement-single-business-membership-boundary), scenarios “Authenticate an individual member”, “Reject invalid authentication”, “Create a tenant member”.
  - Accept: approved first-Admin mechanism, individual email/password login, online first bootstrap, Admin membership management and last-Admin denial; invalid login exposes no data. Password manager/paste work; no onboarding.
  - Check: `pnpm test:db -- access && pnpm test:e2e -- auth` (future).
  - Expected: seeded Admin/Operator journeys pass with Spanish labels and observed role denials.
  - Rollback: disable provisioning/member writes and route entry; retain identities/memberships and access audit.

- [ ] **T2.4 — Enforce local session ownership and offline access policy**
  - Depends: T2.3. Decisions: D05.
  - Surface: future `apps/web/src/data/`, auth/session partition adapter, worker guards, `tests/e2e/session/`.
  - Spec: [Session and local ownership boundary](specs/business-access/spec.md#requirement-session-and-local-ownership-boundary), scenarios “Isolate a shared device”, “Recheck a revoked role”.
  - Accept: user+business partitions for cache/outbox/cursor; approved expiry/logout/reauthentication and unsent recovery; A's queued sale invisible to B and never silently deleted. Revocation fails closed online with honest offline limitation.
  - Check: `pnpm test:e2e -- session && pnpm test:db -- access` (future).
  - Expected: A→B sign-in and remote-revocation fixtures preserve isolated unsent data and deny unauthorized replay.
  - Rollback: disable offline entry if necessary, retain partitions/queues; do not purge data or weaken server checks.

## Group 3 — domain, transactional posting and sync

- [ ] **T3.1 — Define exact amounts, quantities and seven effects**
  - Depends: T1.2. Decisions: D02, D07.
  - Surface: future `packages/domain/src/`, shared validation fixtures, server numeric adapter.
  - Spec: [Exact COP and quantity snapshots](specs/financial-records/spec.md#requirement-exact-cop-and-quantity-snapshots), scenario “Reject unsupported precision and overflow”; [operation totals](specs/financial-reporting-exchange/spec.md#requirement-operation-derived-totals-and-periods).
  - Accept: exact decimal-string/bigint validation on both boundaries, approved quantity scale and negative/baseline rules, no silent rounding. Fixtures: `1.5` COP, `+1`, `01`, `-0`, `1e3`, signed-64 overflow, quantity product fractional COP, 8000 transfer net zero. Safe preparatory integer parser work may start before decisions; task remains incomplete.
  - Check: `pnpm test -- money-effects && pnpm test:db -- money` (future).
  - Expected: identical client/server reject/accept fixture results, exact sums and inverse overflow rejection.
  - Rollback: disable new posting adapter; version contracts without rewriting frozen payloads or persisted money.

- [ ] **T3.2 — Create immutable facts, audit and receipt posting**
  - Depends: T2.1, T3.1. Decisions: none.
  - Surface: future `supabase/migrations/`, posting RPC, `tests/db/posting/`.
  - Spec: [Auditable finance records](specs/financial-records/spec.md#requirement-auditable-finance-records), scenario “Record normal operations”; [frozen identity](specs/offline-financial-sync/spec.md#requirement-frozen-identity-and-receipt-resolution).
  - Accept: seven operations, including paid operating expenses, post snapshots/effects/audit/receipt in one transaction, stable tenant+operation hash uniqueness; same key replay returns receipt, hash mismatch rejects; direct history updates/deletes denied. Failed second transfer leg leaves neither leg. Own table-specific RLS and real-role cross-tenant read/write/receipt exposure tests for facts, effects, audit and receipts as those tables and posting/receipt surfaces are introduced; nonexistent endpoint denial is not authorization proof.
  - Check: `pnpm test:db -- posting` (future).
  - Expected: one accepted effect after repeated replay, zero partial effects under injected failure; table-specific cross-tenant reads/writes and receipt probes against implemented surfaces are denied without exposure or mutation, with permitted same-tenant controls proving the surfaces exist.
  - Rollback: disable new writer/RPC, forward repair schema only; retain facts/audit/receipts.

- [ ] **T3.3 — Add atomic correction primitives**
  - Depends: T3.2. Decisions: D03, D04.
  - Surface: future domain correction reducer, migration constraints/locking, correction RPC, `tests/db/corrections/`.
  - Spec: [Atomic linked correction](specs/financial-records/spec.md#requirement-atomic-linked-correction), scenarios “Correct once under retry and concurrency”, “Roll back a failed replacement”.
  - Accept: approved permissions/date attribution; reason/actor/link retained; one target revision corrected once, retry receipt stable; 12000→15000 purchase produces net 15000; invalid replacement leaves original intact; denied edit audit distinct.
  - Check: `pnpm test -- corrections && pnpm test:db -- corrections` (future).
  - Expected: inverse/replacement atomicity, competing correction rejection and exact report effect pass real concurrent fixtures.
  - Rollback: disable correction entry point, keep all originals/groups; never delete inverse history or revert schema destructively.

- [ ] **T3.4 — Persist local documents and frozen outbox safely**
  - Depends: T2.4, T3.1. Decisions: none.
  - Surface: future `apps/web/src/data/`, local draft/outbox state machine, `tests/client/storage/`.
  - Spec: [Safe offline financial writes](specs/offline-financial-sync/spec.md#requirement-safe-offline-financial-writes), scenario “Create every supported operation offline”; [atomic persistence](specs/offline-financial-sync/spec.md#requirement-atomic-persistence-and-complete-pull), scenario “Retain a failed local form”.
  - Accept: document/outbox/projection atomic; saved only after commit; quota/abort retains form; only creator edits never-sent payload; freeze persisted before send; ownership and all four Spanish statuses visible.
  - Check: `pnpm test -- storage` (future).
  - Expected: all seven queued fixtures, including operating expenses, survive reopen; injected failures create no orphans or false saved feedback.
  - Rollback: disable new saves; preserve DB versions, frozen hashes and queues for compatible recovery.

- [ ] **T3.5 — Push, retries and lost-acknowledgement resolution**
  - Depends: T3.2, T3.4. Decisions: none.
  - Surface: future `supabase/functions/sync/`, `apps/web/src/sync/`, `tests/e2e/sync-push/`.
  - Spec: [Frozen identity and receipt resolution](specs/offline-financial-sync/spec.md#requirement-frozen-identity-and-receipt-resolution), scenario “Resolve a lost acknowledgement”; [safe offline writes](specs/offline-financial-sync/spec.md#requirement-safe-offline-financial-writes), scenarios “Synchronize a retried sale”, “Flag unsafe acceptance”, “Protect synced history while offline”.
  - Accept: same bytes/key/hash after timeout; transient backoff/manual launch/focus retry; expired auth pauses, permanent failures show reason/retain audit; no role-loss overwrite. Multi-tab leader races remain server-idempotent.
  - Check: `pnpm test:db -- sync-push && pnpm test:e2e -- sync-push` (future).
  - Expected: drop response after commit and race two tabs: one sale, one receipt, no edit until resolved; rejected attempts remain visible.
  - Rollback: pause push while retaining outbox/receipts and allow diagnostic read; do not generate replacement keys for unknown outcomes.

- [ ] **T3.6 — Pull with committed visibility and atomic acknowledgement**
  - Depends: T3.5. Decisions: none.
  - Surface: future commit-order DB lock/watermark, pull RPC, client page/cursor/ack transactions, `tests/db/sync-pull/`.
  - Spec: [Atomic persistence and complete pull](specs/offline-financial-sync/spec.md#requirement-atomic-persistence-and-complete-pull), scenario “Restart a pull without skipped facts”; [operation totals](specs/financial-reporting-exchange/spec.md#requirement-operation-derived-totals-and-periods), scenario “Replace provisional totals on acknowledgement”.
  - Accept: all writer paths use transaction-held per-business ordering; paging preserves transaction groups. Delayed A/competing B, aborted A, crash-before-local-commit, repeated page and ack-before-pull fixtures show no skipped/doubled facts. No naive allocation `MAX(sequence)` shortcut.
  - Check: `pnpm test:db -- sync-pull && pnpm test -- sync-pull && pnpm test:e2e -- sync-once` (future).
  - Expected: accepted facts converge exactly once; cursor advances only with local committed pages; provisional overlay replaced once.
  - Rollback: pause pull/upgrade cursor format compatibly; retain old cursors/facts and replay from a safe committed watermark.

- [ ] **T3.7 — Prove old-client, worker and multi-tab upgrade safety**
  - Depends: T3.6. Decisions: none.
  - Surface: future Dexie/payload migrations, service-worker activation handshake, compatibility response, `tests/e2e/upgrades/`.
  - Spec: [Offline-ready shell and outbox-safe upgrades](specs/offline-financial-sync/spec.md#requirement-offline-ready-shell-and-outbox-safe-upgrades), scenario “Upgrade with an old frozen outbox”.
  - Accept: old frozen operation retains identity/hash; compatible server accepts or explicit upgrade-required preserves it; blocked second tab gets guidance; interrupted migration and lease-owner crash recover. No reset-to-fix or indiscriminate API caching; document eviction/private mode limit.
  - Check: `pnpm test:e2e -- upgrades && pnpm test -- migrations` (future).
  - Expected: warm/offline and upgrade fixtures retain queued records and avoid activation during local commits.
  - Rollback: stop worker rollout; retain old compatible assets/readers and additive schemas, never delete private storage.

## Group 4 — operational UI and reporting

- [ ] **T4.1 — Implement catalog and seven record forms**
  - Depends: T3.6. Decisions: D07.
  - Surface: future `apps/web/src/features/records/`, catalog adapter and form/e2e fixtures.
  - Spec: [Auditable finance records](specs/financial-records/spec.md#requirement-auditable-finance-records), scenarios “Record normal operations”, “Reject or correct safely”; [exact snapshots](specs/financial-records/spec.md#requirement-exact-cop-and-quantity-snapshots).
  - Accept: Admin catalog editing; Spanish multi-line cash-or-transfer sale with visible price override, structured supplier item/quantity/unit-cost/line-total snapshots, operating expense with description/amount/paying account, contribution/withdrawal/both transfer directions. Expense examples gas/transport/rent reduce estimated profit and the paying account, but owner withdrawals do not reduce profit. Empty/split sale rejected; no mandatory override-note policy invented; catalog rename leaves old snapshot.
  - Check: `pnpm test -- records && pnpm test:e2e -- records` (future).
  - Expected: all seven create/offline/retry flows pass, failure retains form, historical price/name stays unchanged.
  - Rollback: hide affected forms/routes; retain accepted snapshots and pending queues for compatible replay.

- [ ] **T4.2 — Expose history and explicit correction resolution**
  - Depends: T3.3, T4.1. Decisions: D04.
  - Surface: future history/correction UI, attention resolution, audit views and e2e fixtures.
  - Spec: [Atomic linked correction](specs/financial-records/spec.md#requirement-atomic-linked-correction), both correction scenarios; [safe offline writes](specs/offline-financial-sync/spec.md#requirement-safe-offline-financial-writes), scenario “Protect synced history while offline”.
  - Accept: authorized linked void/replacement with reason, target and actor; no hard delete/offline posted edit; unknown outcome frozen; definitive rejected edit creates linked new attempt and retains old rejection, not a hidden overwrite.
  - Check: `pnpm test:e2e -- corrections` (future).
  - Expected: permission denials and 12000→15000 correction history visible, concurrency attention actionable with no duplicate reversal.
  - Rollback: disable correction UI only; preserve groups/audit and server denial controls.

- [ ] **T4.3 — Retain reconciliation cutoffs and observations**
  - Depends: T4.1. Decisions: D02, D03.
  - Surface: future `apps/web/src/features/reconciliation/`, observation RPC/schema and fixtures.
  - Spec: [Retained reconciliation observation](specs/financial-records/spec.md#requirement-retained-reconciliation-observation), scenario “Preserve a prior cutoff”.
  - Accept: Admin observation stores expected/observed/−2000 difference, note, account/period, basis IDs/watermark; late sale does not mutate original snapshot; separate current comparison; zero money effects and versioned drafts.
  - Check: `pnpm test:db -- reconciliation && pnpm test:e2e -- reconciliation` (future).
  - Expected: snapshot immutable after late facts/correction, difference excluded from postings, Operator denied.
  - Rollback: disable new observations, retain snapshots and labels; no balancing entry or destructive recalculation.

- [ ] **T4.4 — Deliver explainable period summaries**
  - Depends: T4.2, T4.3. Decisions: D02, D03.
  - Surface: future `apps/web/src/features/reporting/`, domain reducers/queries, period fixtures.
  - Spec: [Explainable Spanish COP summaries](specs/financial-reporting-exchange/spec.md#requirement-explainable-spanish-cop-summaries), scenario “Explain a monthly period”; [Operation-derived totals and periods](specs/financial-reporting-exchange/spec.md#requirement-operation-derived-totals-and-periods), scenarios “Separate profit from funds”, “Replace provisional totals on acknowledgement”.
  - Accept: approved expense scope/baseline/timezone/week/correction date reflected in day/week/month; test 36000−12000−3000+10000−4000 = 27000 flow, 21000 estimated profit, 8000 transfer net zero; operating expenses distinct from purchases and owner withdrawals, rejected excluded; local overlays labeled and deduped. Test week/month boundary and correction crossing period.
  - Check: `pnpm test -- reporting && pnpm test:db -- reporting && pnpm test:e2e -- reporting` (future).
  - Expected: every figure explains contributing records; opening baseline not assumed from zero test fixture; no claimed formal accounting profit.
  - Rollback: disable derived summary views/rebuild projections from immutable facts, never edit business history to fit totals.

## Group 5 — guarded Excel exchange

- [ ] **T5.1 — Stage bounded, typed workbook previews**
  - Depends: T4.1. Decisions: D07.
  - Surface: future `apps/web/src/features/exchange/`, parsing adapter and `tests/fixtures/exchange/`.
  - Spec: [Guarded Excel exchange](specs/financial-reporting-exchange/spec.md#requirement-guarded-excel-exchange), scenario “Preview and repeat an import”; [Bounded typed Excel posting](specs/financial-reporting-exchange/spec.md#requirement-bounded-typed-excel-posting), scenario “Reject an unsafe workbook and flag copied rows”.
  - Accept: map/preview exact typed fields including operating-expense type/description/account with documented tested byte/sheet/row/column/cell/expanded limits; reject formulas/unsafe formats/encryption/macros; retain errors/source IDs; preview cross-file source duplicates, not just file hash; no posting on preview. Prefer installed parser, assess necessary dependency only during implementation.
  - Check: `pnpm test -- exchange-preview` (future).
  - Expected: valid/invalid/duplicate, malformed dates, localized COP, formula and oversized fixtures classified without formula execution or server mutation.
  - Rollback: disable import selection/preview; preserve staged metadata without touching posted history.

- [ ] **T5.2 — Confirm import with durable row receipts**
  - Depends: T5.1, T3.6. Decisions: D06.
  - Surface: future import RPC/batch-row identity constraints, confirmation/resume UI, DB/e2e fixtures.
  - Spec: [Bounded typed Excel posting](specs/financial-reporting-exchange/spec.md#requirement-bounded-typed-excel-posting), scenario “Resume an interrupted confirmation”; [Guarded Excel exchange](specs/financial-reporting-exchange/spec.md#requirement-guarded-excel-exchange), scenario “Preview and repeat an import”.
  - Accept: selected whole-batch/per-row semantics visible; server role/tenant/exact validation, stable row source/operation IDs, facts/audit/receipt atomicity; timeout resumes original outcomes; copied rows flagged while legitimate identical sales can be reviewed explicitly. Import participates in commit-safe pull ordering.
  - Check: `pnpm test:db -- exchange-post && pnpm test:e2e -- exchange-post` (future).
  - Expected: disconnect after committed row A/before B outcome, retry and new-file copy create no repeated A; failed row behavior matches recorded D06 decision.
  - Rollback: pause confirmation, retain batches/outcomes/receipts and resume identity; correct accepted rows only through authorized linked corrections.

- [ ] **T5.3 — Export portable safe records**
  - Depends: T4.4, T5.2. Decisions: none.
  - Surface: future export adapter/UI, export schema docs and round-trip fixtures.
  - Spec: [Portable export and recoverable backup](specs/financial-reporting-exchange/spec.md#requirement-portable-export-and-recoverable-backup), scenario “Export safely and restore independently” (portable half).
  - Accept: Admin-only retained records/audit export, including operating expenses and their distinct type/description/account, with exact COP and timestamps, untrusted `=`, `+`, `-`, `@` text safely typed/neutralized; reopen/round-trip preserves meaning. Label portable exchange, not database backup; no destructive import replacement.
  - Check: `pnpm test -- exchange-export && pnpm test:e2e -- exchange-export` (future).
  - Expected: exported malicious text remains text, exact amounts round-trip and denied Operator export leaks no data.
  - Rollback: disable export route/download only; retain business records and backup plan separately.

## Group 6 — acceptance, operations and pilot

- [ ] **T6.1 — Verify integrated offline and accessible screens**
  - Depends: T3.7, T4.4, T5.3. Decisions: none.
  - Surface: future `tests/e2e/`, app accessibility fixes, CI and actual operational screen evidence locators; existing reference PNGs untouched by this review.
  - Spec: all scenarios in all four specs, especially “Create every supported operation offline”, “Resolve a lost acknowledgement”, “Isolate a shared device”, “Explain a monthly period”, “Resume an interrupted confirmation”.
  - Accept: initialized permitted device creates seven types, including operating expenses, offline→reconnect once, with attention cases, multi-tab/crash, auth/RLS, import/export and corrections. Capture ACTUAL operational screens at 360/375/430/768/1280 as applicable, light/dark; test keyboard/dialog/tabs, zoom, focus under sticky UI, labels, error retention, reduced motion and destructive contrast. Test Chrome and WebKit/iPhone-class and Pixel-class contexts; record real-device limits honestly.
  - Check: `pnpm lint && pnpm format:check && pnpm typecheck && pnpm build && pnpm test:e2e -- acceptance` (future), plus observed manual/device evidence.
  - Expected: named scenarios/test counts and actual screen locators recorded; old foundations/components PNGs never used as operational proof. Missing device/manual proof blocks acceptance.
  - Rollback: disable affected release features/worker version while keeping backward-compatible readers, accepted facts and queues.

- [ ] **T6.2 — Prove backup, recovery and non-destructive rollback**
  - Depends: T5.3, T3.7. Decisions: D09.
  - Surface: future `docs/operations.md`, deployment/monitoring configuration, isolated backup/restore evidence.
  - Spec: [Portable export and recoverable backup](specs/financial-reporting-exchange/spec.md#requirement-portable-export-and-recoverable-backup), scenario “Export safely and restore independently” (recovery half).
  - Accept: chosen plan/host/region/retention/RPO/owner, tested full backup/Auth/schema/policy/receipts recovery in isolation, export separately verified, alerts and writer-fencing plan. Account for post-backup facts and never overwrite live history/queues; explicitly document unsent sole-device/eviction limits. No live DB reset/PITR assumption.
  - Check: `pnpm check:release` (future) plus recorded isolated restore procedure and measured recovery result.
  - Expected: restored fixture facts/audit/receipts/roles verified, RPO/owner documented, live records/queues untouched; XLSX alone fails backup gate.
  - Rollback: stop pilot rollout/writers; use tested compatible deployment/forward repair; destructive down migrations forbidden.

- [ ] **T6.3 — Close evidence gaps before pilot promotion**
  - Depends: T6.1, T6.2. Decisions: none (all D01–D09 must now be resolved through dependencies).
  - Surface: future release checklist/runbook, this task evidence/progress table and draft `develop` tracker.
  - Spec: every requirement/scenario in the [four specs](proposal.md#capabilities); proposal success criteria.
  - Accept: enumerate observed proof for every requirement, no OPEN decision on shipping path, no missing/failed fixture concealed, reviewed child chain integrated and tracker release prerequisites met. Human pilot acceptance must be recorded when actually obtained.
  - Check: `pnpm check:plan && pnpm check:release` (future), inspect observed review/runtime/manual evidence.
  - Expected: truthful GO only with complete observed proof; otherwise BLOCKED with next action, never inferred approval.
  - Rollback: keep tracker draft/no-merge and pilot disabled; retain all evidence/data, no forced promotion.

## Requirement coverage index

Exact scenario names are listed in the owning tasks; T6.1/T6.3 verify full integration rather than substitute for unit evidence.

| Specification requirement | Owning tasks |
|---|---|
| Access: Single-business membership boundary | T2.1, T2.3 |
| Access: Session and local ownership boundary | T2.4 |
| Records: Auditable finance records | T3.2, T4.1 |
| Records: Exact COP and quantity snapshots | T3.1, T4.1 |
| Records: Atomic linked correction | T3.3, T4.2 |
| Records: Retained reconciliation observation | T4.3 |
| Sync: Safe offline financial writes | T3.4, T3.5, T4.1 |
| Sync: Frozen identity and receipt resolution | T3.2, T3.5 |
| Sync: Atomic persistence and complete pull | T3.4, T3.6 |
| Sync: Offline-ready shell and outbox-safe upgrades | T2.2, T3.7 |
| Exchange: Explainable Spanish COP summaries | T4.4 |
| Exchange: Guarded Excel exchange | T5.1, T5.2 |
| Exchange: Operation-derived totals and periods | T3.1, T3.6, T4.4 |
| Exchange: Bounded typed Excel posting | T5.1, T5.2 |
| Exchange: Portable export and recoverable backup | T5.3, T6.2 |

## Progress table

| Group | Task IDs | Status | Last verified task/branch/evidence | Next gate |
|---|---|---|---|---|
| Planning | P0 | VERIFIED | Current implementation evidence below; branch 01-foundation-a, no commit | D01 approved; user owns D02–D09 |
| 1 Foundation | T1.1, T1.2 | IN_PROGRESS / PARTIAL | T1.1 scaffold passed; T1.2 corrects unsafe DB runner isolation and plan-link validation | Recheck T1.2 before T2.1/T2.2 |
| 2 Access/shell | T2.1, T2.2, T2.3, T2.4 | UNSTARTED | None / absent / PENDING | T1.2; D08 then D05 |
| 3 Domain/sync | T3.1, T3.2, T3.3, T3.4, T3.5, T3.6, T3.7 | UNSTARTED | None / absent / PENDING | D02/D07; D03/D04 for correction |
| 4 Operations | T4.1, T4.2, T4.3, T4.4 | UNSTARTED | None / absent / PENDING | Domain/sync and D02–D04/D07 |
| 5 Exchange | T5.1, T5.2, T5.3 | UNSTARTED | None / absent / PENDING | T4.1; D06/D07 |
| 6 Release | T6.1, T6.2, T6.3 | UNSTARTED | None / absent / PENDING | Integrated proof; D09 |

## Session resume and handoff protocol

1. Read proposal → all four specs → design/register → tasks/progress and latest task evidence. Files are authoritative; do not depend on chat/Engram memory to reconstruct policy.
2. Inspect current repository state if Git exists: future `git status --short`, `git branch --show-current`, `git log --oneline -5`, and diff from the recorded parent. Preserve unfamiliar user work. If Git/tooling is absent, record BLOCKED and obtain separately authorized setup; do not pretend commands ran.
3. Locate last verified task/slice, actual branch/parent/commit, failed/missing proof and all OPEN decision gates. Check current workflow prerequisites, including the historical unverified tooling blocker; do not invoke lifecycle recovery from this documentation plan.
4. Run available prerequisites and the last relevant focused check against current bytes. Record actual commands, outputs/counts and missing tools; proposed scripts are not evidence.
5. Choose the next dependency-complete, decision-unblocked task (T1.1 after P0 is the first safe foundation). Work only its cohesive slice, fixtures and docs. Additional child slices keep stable parent task ID and chosen feature chain.
6. At handoff update per-task evidence, progress/next gate, branch/parent, commands/results, runtime locators, failures/missing proof and next unblocked step. If a choice changes, update the centralized register/specs and mark affected proof stale. Keep checkboxes empty until observed acceptance.

## Documentation review evidence

Historical: checker PASSed 61 links, 24 tasks, 9 decisions, 15 requirements, 28 scenarios and 24 fields. Stale scope/Git check failed because Git existed; no snapshot remains. Never runtime/approval evidence. T2.1/T3.2 ownership and 44px-to-48px wording were corrected; Engram registration failures resolved.

## Current implementation evidence

Historical registration failures above were resolved by a later successful retry/readback; mirror records must be synchronized again after current edits. The current local files and implementation logbook take precedence over old snapshots.

### P0 — verified starting boundary

- Route: direct implementation of the authorized plan, not an sdd-apply invocation. The prior SDD tooling issue has not been declared fixed.
- Actual root is Micu, local branch hot-dog-finance-mvp/01-foundation-a is unborn; no commits/remote operations. Preserve all pre-existing untracked planning/tool files.
- Node26.5.0/npm11.17.0 available; Docker29.7.2 responds. pnpm was not global; exact project bootstrap installed dependencies and generated the lockfile. Supabase CLI/database/browser harness are not yet configured.
- D01 approved by explicit user answer “Incluir gastos operativos”; D02–D09 OPEN, decision owner: user. Each remaining gate stays mapped to its affected tasks. No fixture resolves policy.
- Structural plan check: references and DAG/decision gates remain subject to the current T1.2 check:plan implementation; the embedded historical checker is not current proof.

### T1.1 — scaffold checking

- Status: VERIFIED at scaffold scope after targeted independent correction recheck. Branch: hot-dog-finance-mvp/01-foundation-a; commit/PR: absent.
- Scope: root workspace/quality scripts, apps/web React/TypeScript/Vite Spanish scaffold, packages/domain COP export, one rendered-interface fixture, README. No financial persistence/offline/auth behavior.
- RED: npm test -- App.test.tsx exit1, missing ./App before implementation. GREEN: one test passed focused and full; lint/format/types/build passed. Initial matcher-type compilation failure corrected by including tests/setup.ts.
- Runtime: local Vite HTTP smoke checked es-CO HTML and transformed entry, then shut down. No browser screenshot/device proof implied.
- Independent commands: npm run typecheck && npm test && npm run build exit0, one test; unmatched suite probe exit1 as expected. Node/peer semver probes verified current runtime; advertised Node range was too broad.
- Scoped correction: Node support is ^24.15.0 || >=26.0.0 (excludes unsupported25); removed stale OPEN expense dependency. Independent targeted recheck resolved the prior observations; T1.2 remains UNSTARTED.
- Rollback: new scaffold/config only before any application data exists. Do not reset Git, delete previous specs, clear queues or claim a live-schema rollback.
- Current plan structural check passed: 63 local links, 24 task entries, 9 decision rows, 15 requirements, 28 scenarios and 24 labeled fields; DAG/gates allow approved D01 and completed tasks. The old no-Git/all-OPEN checker remains historical.
- Final normalization was unchanged; format:check and exact Node-contract/approved-D01 assertions passed. An earlier ad-hoc transitive-helper diagnostic failed MODULE_NOT_FOUND and is not passing evidence.
- Native review: the user-confirmed post-restart retry completed all three bound risk/readability/reliability inspections of the 22-file foundation, with no findings. Lineage `review-7ed0c3083e0992f7` approved the frozen scaffold target; exact acknowledgement returned `gentle-ai.review-acknowledged/v1`, `action: acknowledged`, `authority: burned`. No correction or publication occurred; this static review does not replace executed/runtime proof.
- Next: T1.2 harness. Auth/session/DB/browser/CI/restore and every downstream task remain pending. No native delivery receipt, deployment or complete-MVP acceptance is claimed. Do not resume or acknowledge the consumed foundation review again.

### T1.2 — isolated verification harness

- Status: IN_PROGRESS / PARTIAL. Branch: hot-dog-finance-mvp/01-foundation-a; commit/PR: absent. Parent assessment confirmed unsafe root-config DB runner and incomplete plan-link validation; acceptance is pending this correction recheck.
- Parent assessment invalidated the prior DB harness claim: it read/reset root configuration, accepted extra arguments and skipped cleanup after child failure. New safe-mock public-CLI regressions pass for exact suite arity/no child, per-run workdir/config, no reset, failed-start no cleanup, query failure cleanup, cleanup failure propagation, broken links/anchors, fenced history and external URLs.
- Final local checks passed: full `npm test` 3 files/10 tests; `npm run test:e2e -- harness` 1 Chromium test; lint, format check, typecheck, build and `check:plan` (63 local links, 24 tasks, 9 decisions, 43 requirement/scenario headings). `npm run test:db -- harness` created fresh workdir `/tmp/opencode/micu-t12-db-zBrhGP`, project `micu-t12-86d9f137-b5e3-48` and port 56489, then passed seed, local `authenticated` role, `auth.uid()` helper and transaction smoke before its own cleanup. No Docker labels, volumes or Vite server remained.
- The runner now passes an explicit fresh workdir to every CLI command, copies only `seed.sql`, never reads root `supabase/config.toml` or runs `db reset`, and cleans only after successful start. The two initial corrected SQL failures cleaned their own exact workdirs; no unrelated resource was reset or stopped. This remains harness-only evidence, not app Auth/RLS/tenant/finance/offline proof.
- Negative evidence: unmatched Vitest filter, unknown DB suite and release gate exited nonzero. The existing CI `forbidOnly` probe remains recorded; remote CI has not run. `check:release` remains BLOCKED for financial behavior, manual pilot and isolated recovery evidence. D01 remains APPROVED; D02–D09 OPEN. T1.2 stays PARTIAL pending the parent independent targeted recheck; no review PASS is claimed.
- Early mock fixtures used `/tmp` through `tmpdir()` before the test source was corrected to `/tmp/opencode`; they had no Docker or repository effect and remain undeleted for parent cleanup.
- Final partial-start correction: a parent mock proved old `started=true` occurred too late when `start` created an owned partial resource then exited 41. The runner now marks `startAttempted` immediately before start after preflight, then cleans via the same workdir after any attempted start. Public CLI RED/GREEN regression preserves exit 41, removes only the owned fake resource, and preserves a foreign-data SHA-256. Focused result: 1 file/8 tests, lint, typecheck and format check passed; no DB/browser/full suite reran. Status remains IN_PROGRESS/PARTIAL pending parent final targeted recheck.

### T1.2 — current parent handoff

- IN_PROGRESS/PARTIAL; all 5 generic blockers resolved. Batch 1: DB ownership/root reset, extra args, query cleanup, CI npm cache, plan links. Batch 2: only the remaining partial-start cleanup. Targeted mock start creates owned resource/exits 41; same-workdir stop removes it; foreign/root-config hashes unchanged and 41 preserved. Mock only, not DB-failure hardware; prior writer separately observed authenticated role/`auth.uid()`/transaction and Chromium passed once.
- Parent `format:check && typecheck && test && build && check:plan` PASS: 3 files/10 tests, 63 links, 24 tasks, 9 decisions, 43 headings; Docker `name=micu-t12`: none. CI NOT RUN; release BLOCKED for financial/manual-pilot/backup-restore proof; no T2+. D01 APPROVED, D02-D09 OPEN. W1 review `review-7ed0c3083e0992f7` BURNED/no findings; do not resume.
- Native STATUS/offered START: consent v3 HIGH, separate W2, 19 paths/893 lines, risk/resilience/readability/reliability; baseline `ab689e94aff15c8bc3013cddf69a9205256a1779`, candidate `c12e1e843bf8f2b67bea083fe7475915cdb92d07`, target `50839fcef5a57ccc452240ba5bdd1e6f0c5d35eda0bf4fdafa52855199594c46`. Required consent pending: no result/approval/receipt, never infer from W1. After no T1.2 containers, parent removed 79 marked `/tmp/opencode` and 16 marked legacy `/tmp` fixtures; caches/images kept, repo unaffected; do not recreate/delete scratch.
