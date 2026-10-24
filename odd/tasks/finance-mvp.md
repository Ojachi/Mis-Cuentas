# Finance MVP implementation
Objective: implement the approved finance MVP and its resumable OpenSpec task plan. Branch: hot-dog-finance-mvp/01-foundation-a; no commits or remote delivery yet.
Route: direct ODD implementation; existing OpenSpec artifacts are requirements, not an invocation of an SDD phase. Delivery: auto-chain / feature-branch-chain / develop tracker. Test runner: Vitest 5.0.5 plus DB/browser/CI harnesses under T1.2 corrective recheck.

## Specs

- S1: "Ok listo, entonces yo creo que podemos empezar con el desarrollo, todas las tareas que tenemos establecides, comencemoslas, realicemos este MVP". Implement P0 and T1.1–T6.3 from [the development plan](../../openspec/changes/hot-dog-finance-mvp/tasks.md), preserving the four specifications and the central decision register. Every task needs observed acceptance; an OPEN decision blocks its affected work, not unrelated foundation work.
- S2: "Incluir gastos operativos". The user selected this option for: "¿El MVP debe registrar también gastos operativos, como gas, transporte y alquiler, y descontarlos de la ganancia estimada?" Add operating expenses to the approved scope; estimated profit is accepted sales minus supplier purchases minus operating expenses. Owner withdrawals and internal transfers are not operating expenses. Update linked requirements before implementation; no inventory or formal accounting is introduced.
- S3: Existing architecture, visual direction and constraints remain those in [the design](../../openspec/changes/hot-dog-finance-mvp/design.md). Shared cloud authority plus per-device offline cache/outbox, exact COP, immutable linked corrections, safe sync, guarded Excel exchange and recoverable backups remain required. Unresolved D02–D09 must not be inferred from fixtures.

## Tasks

- W0 | S1–S3 | inline | VERIFIED | D01 propagated to scope, financial records/reporting/sync, task fixtures and visual reference note; P0 state recorded. Commit: absent.
- W1 / T1.1 | S1,S3 | inline | VERIFIED | Buildable React/TypeScript/Vite workspace, domain package import, Spanish nonfinancial scaffold and quality scripts. RED missing App observed; GREEN 1 test/build/types/lint/format/HTTP smoke. Independent targeted recheck resolved all observations. Risk: item 5 (new dependencies and build configuration). Commit: absent.
- W2 / T1.2 | S1,S3 | delegated | IN_PROGRESS / PARTIAL | Previous local DB harness read root Supabase configuration and did not preserve cleanup on child failure. Corrective isolated-run namespace, cleanup and link-gate recheck in progress. Risk: items 1 (existing DB loss) and 5 (test/dependency/CI setup). Commit: absent.
- W3 / T2.1–T2.4 | S1,S3 | inline | UNSTARTED | Access, tenant boundaries and minimal offline shell. Blockers include D08 then D05. Commit: absent.
- W4 / T3.1–T3.7 | S1–S3 | inline | UNSTARTED | Exact financial domain, server posting, corrections and offline synchronization. Blockers include D02,D03,D04,D07. Commit: absent.
- W5 / T4.1–T4.4 | S1–S3 | inline | UNSTARTED | Operational forms including expenses, history, reconciliation and reports. Commit: absent.
- W6 / T5.1–T5.3 | S1–S3 | inline | UNSTARTED | Guarded workbook import/export. Blockers include D06. Commit: absent.
- W7 / T6.1–T6.3 | S1–S3 | inline | UNSTARTED | Integrated accessible/offline checks, recovery proof and pilot acceptance. Blockers include D09. Commit: absent.

The existing plan owns individual task acceptance/dependencies; this logbook records implementation intent and current evidence without creating another competing task specification. Route evidence: W0/W1 were inline. W2 uses one bounded writer for the context backstop after the accumulated review handoff; no parallel writers or claimed runtime context telemetry. A fresh read-only verifier is required for the named high-risk surfaces after their own checks. No push, PR, deployment or merge is authorized by local implementation.

Forecast: total authored lines unknown and likely above 400; preserve the chosen feature-branch chain and slice coherent work units with tests/docs, not arbitrary task checkboxes. Current slice: foundation only; later DB/security work is a separate unit. No remote branch/PR operation has been authorized.

## Log

### L1 — original development request

"Ok listo, entonces yo creo que podemos empezar con el desarrollo, todas las tareas que tenemos establecides, comencemoslas, realicemos este MVP"

### L2 — explicit product choice

Question: "¿El MVP debe registrar también gastos operativos, como gas, transporte y alquiler, y descontarlos de la ganancia estimada?"

Answer: "Incluir gastos operativos". D01 is approved; D02–D09 remain unresolved.

### L3 — initial state and execution boundary

- Actual repository root: Micu. Git exists, branch master is unborn, with no commits; .agents/, .atl/, .opencode/, openspec/ and skills-lock.json are pre-existing untracked material. Preserve them and do not indiscriminately stage them.
- Node v26.5.0 and npm 11.17.0 are available. pnpm and Supabase CLI are not on PATH. Docker server reports 29.7.2. No app or root package manifest exists yet.
- Package registry reports pnpm 12.14.0. Any dependency versions/engines must be checked before installation. Use a project-scoped bootstrap, not a global package-manager installation.
- Receipt-driven review is on, decided by the global user preference. Candidate consent remains separate. Earlier untracked-inventory assessment was not a review or approval.
- CodeGraph has no project index; its tool instructed fallback to ordinary file reads. No index initialized.
- This is the direct implementation route. No sdd-apply/sdd-verify actor is launched and the prior missing sdd-attempt observation is not treated as resolved or used as permission to launch an SDD phase.
- No application, DB, browser, restore or CI evidence exists yet. All checks remain pending until actually run.

### L4 — scope and foundation evidence

- D01 propagated: seven operation types; profit S−P−E, combined flow S−P−E+C−W. Example with sale 36000, purchase 12000, expense 3000, contribution 10000, withdrawal 4000 and transfer 8000 gives profit 21000 and flow 27000. D02–D09 remain OPEN with the user as decision owner.
- Created local feature branch hot-dog-finance-mvp/01-foundation-a; no baseline commit exists. No remote state was inspected or changed, and no unrelated untracked material was staged.
- Installed exact dependencies via npm exec --yes --package=pnpm@12.14.0 -- pnpm install: exit0, 195 packages, three workspaces, no engine/peer warnings; pnpm-lock.yaml generated. Node26.5.0 supported.
- Observed RED: npm test -- App.test.tsx exited1 because ./App did not exist. Implemented Spanish scaffold without fake balances or persistence/offline claims; domain package exports only COP, no unapproved financial policy.
- Observed GREEN: focused/full Vitest test 1/1 passed; npm run lint, format:check, typecheck and build passed after including tests/setup.ts for Vitest matcher types. Final formatter rerun was unchanged. Local Vite HTTP smoke served es-CO HTML and transformed React entry, then stopped.
- Independent verification reran typecheck/test/build successfully and proved unmatched filter exits1. It found an overbroad Node engine range and a stale OPEN expense-scope bullet; one correction batch narrows Node to ^24.15.0 || >=26.0.0 and corrects that bullet. Targeted independent recheck pending. npm ls --all --offline is not reliable evidence for this pnpm tree and was not treated as a clean dependency verdict.
- T1.2 remains UNSTARTED. No auth, database schema, financial posting, service worker, DB/browser/CI/restore proof or MVP completion is claimed.

### L5 — foundation closure

- Independent targeted recheck confirmed Node-range, D01-list and evidence-handoff observations resolved. T1.1 is complete at scaffold scope only; T1.2 and downstream implementation remain unstarted.
- Final formatter was unchanged and format:check passed. A first ad-hoc diagnostic failed to load a guessed transitive semver path; no application/config defect was inferred. Replacement exact-contract assertions passed; this diagnostic failure is not represented as passing evidence.
- Current read-only plan check passed: 63 links, 24 task entries, 9 decision rows, 15 requirements, 28 scenarios, 24 labeled HTML fields, acyclic dependencies and matching remaining OPEN gates. Unlike the historical checker it permits approved D01 and completed P0.
- No commits/push/PR/cloud deployment. At this point native review had not issued an approval or receipt; the later terminal result is recorded in L6.

### L6 — terminal foundation review

- After the user confirmed restarting OpenCode and authorized retry, the same three bound reviewers completed inspection of all 22 frozen foundation paths: risk, readability and reliability, with no findings. The earlier access failures are historical, not review evidence.
- Native lineage `review-7ed0c3083e0992f7` approved target `sha256:8de109b7f9f50d2e9e8f55ed5f19e00090203fb5ef41c4ce4459b1bb21a7e7eb`. The exact returned acknowledgement was executed once; `gentle-ai.review-acknowledged/v1` confirmed `action: acknowledged` and `authority: burned`, consuming revision `sha256:1f77ad5d3f07635f3219a99886058f6a744f055879ce7f7bfc6da9f02c26262b`.
- No correction was required. This is a bounded static scaffold review, not financial/auth/offline/runtime acceptance or authorization to publish. Prior executed checks remain separate evidence. No trailing review restart or duplicate acknowledgement is needed for this consumed target.
- P0 and T1.1 remain VERIFIED; T1.2 and the financial MVP remain UNSTARTED. No commits, staging, push, PR or deployment occurred.

Next development unit: T1.2 isolated verification harness, preserving the OPEN D02–D09 gates. Foundation review is closed; do not resume its consumed authority.

### L7 — T1.2 isolated verification harness

- T1.2 acceptance was observed locally: root named-suite contracts select unit/domain/client, DB and browser fixtures; unmatched/unknown filters exit nonzero; `check:plan` validates 24 task entries, 9 decisions, 43 requirement/scenario headings and the acyclic dependency graph with D01 APPROVED and D02–D09 OPEN.
- The disposable local Supabase project label is `micu-t12-harness` on PostgreSQL port 54342. `test:db -- harness` started it, reset only that isolated project, seeded two synthetic harness IDs, exercised `auth.uid()` with a synthetic request claim and a transaction, then stopped it with `--no-backup`. This is harness evidence only, not application Auth, RLS, tenant, financial, or offline proof.
- Playwright Chromium passed one real Vite-scaffold browser fixture: `es-CO`, Spanish heading and the visible no-save/no-offline limitation. Chromium was downloaded to the user cache. CI wiring runs the same actual local commands; remote CI has not run.
- Final local results: lint, format check, typecheck, full Vitest (3 files/5 tests), build, plan check, DB harness and browser harness passed. The release gate intentionally exits 1 while financial behavior, manual pilot acceptance and isolated backup-recovery evidence are absent. CI `forbidOnly` was separately proven by a temporary non-retained fixture; the test runner rejected it before listing tests.
- Negative probes: unmatched Vitest filter, unmatched Playwright filter and unknown DB suite each exited nonzero. No commits, staging, push, PR, deployment, cloud account, remote credential inspection, or review operation occurred. D02–D09 remain OPEN.

### L8 — T1.2 isolation correction

- Parent assessment invalidated the prior VERIFIED claim: the old DB runner read root `supabase/config.toml`, reset it, accepted extra arguments and could bypass `finally`. The assessment was high/unassessable for untracked inventory, not low. T1.2 is IN_PROGRESS/PARTIAL pending independent recheck; risks are item 1 (existing DB loss) and item 5 (config/dependencies).
- RED was observed only through a fake `supabase` executable: extra arguments invoked children, query failure skipped cleanup, and broken file/anchor links passed the old plan CLI. New public-CLI regressions cover exact suite arity, no child for rejected input, generated workdir/config identity, no reset, failed start without cleanup, query failure with cleanup, cleanup failure propagation, broken file/anchor rejection, fenced-history ignore and external URL ignore.
- Corrected runner creates a fresh `/tmp/opencode/micu-t12-db-*` workdir, short UUID project ID and random DB port, copies only `seed.sql`, and passes `--workdir` to start/query/stop. It never reads the root config or runs `db reset`; cleanup happens only after a successful start and preserves the primary failure. The first corrected SQL shape and role ordering failed safely and its owned resources were stopped using their exact workdirs; no foreign resource was touched.
- Final local DB recheck passed with workdir `/tmp/opencode/micu-t12-db-zBrhGP`, project `micu-t12-86d9f137-b5e3-48`, DB port 56489: synthetic seed IDs, local `authenticated` role, `auth.uid()` request-claim helper and transaction smoke completed, then its containers/volume were removed. Browser harness passed once. Docker labels and port 4173 were empty afterward.
- Final root evidence: lint, format check, typecheck, Vitest 3 files/10 tests, build and current plan check (63 local links, 24 tasks, 9 decisions, 43 requirements/scenarios) passed. Release remains BLOCKED; remote CI, pilot and recovery are NOT RUN. D01 remains APPROVED and D02–D09 OPEN.
- Initial mock-fixture test runs used `/tmp/micu-t12-plan-*` and `/tmp/micu-t12-regression-*` through `tmpdir()`; no Docker or repository state was changed, the paths were not deleted, and the test source now pins all later fixture scratch to `/tmp/opencode`.

### L9 — T1.2 partial-start cleanup correction

- Parent targeted recheck reproduced the remaining blocker: an attempted `start` could create an owned partial resource and exit 41 before the old `started` flag became true, leaving it uncleaned. This is the same item 1 cleanup blocker; no new product scope or task acceptance is claimed.
- RED: the public CLI regression fake created an owned resource at start, exited 41, and observed no stop. GREEN: `startAttempted` is marked only after preflight/workdir/config validation and immediately before invoking start; cleanup uses the same owned workdir after every attempted start outcome while preserving exit 41. The mock confirmed the owned resource was absent after cleanup and a foreign-data SHA-256 was unchanged.
- Focused checks passed: `npm test -- scripts.test.ts` (1 file/8 tests), lint, typecheck and format check. No Docker, browser, remote CI or full-suite proof ran for this control-flow-only correction. T1.2 remains IN_PROGRESS/PARTIAL pending the parent final targeted recheck.

### L10 — T1.2 current parent handoff

- W2 is IN_PROGRESS/PARTIAL. All five reported generic verifier blockers are resolved. The first correction batch fixed DB ownership/root reset, extra arguments, query cleanup, CI npm cache and plan links. The second correction was only the same remaining partial-start cleanup, not a new full sweep.
- Final independent targeted mock-start result: start creates its own resource and exits 41; same-workdir stop removes the owned resource; foreign and root-config SHA-256 values remain unchanged; exit 41 is preserved. This is mock coverage of the final partial-start control flow, not real DB-failure hardware proof. Prior writer DB evidence separately covered authenticated role, `auth.uid()` and a transaction; one Chromium browser fixture passed separately.
- Parent observed `npm run format:check && npm run typecheck && npm test && npm run build && npm run check:plan` PASS: 3 files/10 tests, 63 local links, 24 tasks, 9 decisions and 43 requirement/scenario headings. Docker filtered by `name=micu-t12` returned no resources. Remote CI was NOT RUN; release remains expected BLOCKED for future financial behavior, manual pilot and backup/restore evidence. No T2+ product features have started.
- D01 expenses is APPROVED; D02-D09 remain OPEN. Native W1 review `review-7ed0c3083e0992f7` was acknowledged and BURNED with no findings; do not resume it. Separate W2 native candidate consent is required and pending: HIGH across risk, resilience, readability and reliability; 19 changed paths/893 authored changed lines; baseline `ab689e94aff15c8bc3013cddf69a9205256a1779`, candidate `c12e1e843bf8f2b67bea083fe7475915cdb92d07`, target SHA-256 `50839fcef5a57ccc452240ba5bdd1e6f0c5d35eda0bf4fdafa52855199594c46`. No results, approval or receipt exist; do not infer consent from the old foundation grant.
- Parent cleanup, after verifying no T1.2 containers, removed 79 recognized test directories under `/tmp/opencode` and 16 legacy `/tmp` fixture folders after confirming their mock/plan markers. Shared browser/dependency caches and Docker images were retained; repository impact was none. Do not recreate or manually delete scratch paths.
