# Finance MVP implementation
Objective: implement the approved finance MVP and its resumable OpenSpec task plan. Branch: develop; initial snapshot 06feca1 is published to Ojachi/Mis-Cuentas on main and develop.
Route: direct ODD implementation; existing OpenSpec artifacts are requirements, not an invocation of an SDD phase. Delivery: commit and push each verified task to develop; reserve main for stable promotion, without per-feature branches or PRs. Test runner: Vitest 5.0.5 plus isolated DB/browser harnesses. Native RDD reviews are disabled for this repository by explicit user instruction; functional verification remains required.

## Specs

- S1: "Ok listo, entonces yo creo que podemos empezar con el desarrollo, todas las tareas que tenemos establecides, comencemoslas, realicemos este MVP". Implement P0 and T1.1–T6.3 from [the development plan](../../openspec/changes/hot-dog-finance-mvp/tasks.md), preserving the four specifications and the central decision register. Every task needs observed acceptance; an OPEN decision blocks its affected work, not unrelated foundation work.
- S2: "Incluir gastos operativos". The user selected this option for: "¿El MVP debe registrar también gastos operativos, como gas, transporte y alquiler, y descontarlos de la ganancia estimada?" Add operating expenses to the approved scope; estimated profit is accepted sales minus supplier purchases minus operating expenses. Owner withdrawals and internal transfers are not operating expenses. Update linked requirements before implementation; no inventory or formal accounting is introduced.
- S3: Existing architecture, visual direction and constraints remain those in [the design](../../openspec/changes/hot-dog-finance-mvp/design.md). Shared cloud authority plus per-device offline cache/outbox, exact COP, immutable linked corrections, safe sync, guarded Excel exchange and recoverable backups remain required. D02–D09 now have explicit approved policies recorded in L16 and the central register; fixtures do not replace acceptance evidence.
- S4: "Listo ahora, quiero que completemos todas las tareas que faltan por hacer, lo ideal seria que pusieras a un agente por cada una haciendolas al mismo tiempo, peor entiendo que algunas se pueden solapar y volverse una combinaicon no deseada entonces esta en tu criterio como hacerlas todas, pero lo que quiero es que orquestes agentes para hacerlas lo mas rapido posibles tu revisaras las tareas y determinaras cuales se podran ahcer al mismo tiempo sin ningun inconveniente. Para los agentes usalos con modelos de terra y de deepseek flash de eepseek no de opencode. Para que los tokens duren mas, no vayas a utilizarlos con modelos que consuman mas tokens. Y el tema de los checks de seguridad pues si hay que hacer correciones pues hazlas, no me pidas permisos que si se ahcen o no, esta bajo tu criterio si se deberian de hacer si son menores y no se necesitan de hacer o si ya tienen un impacto tan gigantesco que cambia la vision del proyecto pues ahi si preguntamelos, pero que sea ya cunado no haya nada mas que hacer. Entonces dale empieza con todo eso, despues de cada tarea completada, ahces un commit y pusheas a develop."

- S5: "Bueno, entonces el error que hay pendiente si no bloquea lo demas dejalo pendiente y avancemos, preguntame entonces todo lo que requieras para terminar todas las tarea y etonces que las vayas haciendo hasta que todo este completo, si hay mas erores que no puedes resolver por tu cienta pues los vas anotando y si se puede seguir sigue con las demas y ya cuando no quede mas por hacer ahi si me muestras los errores para mirar como los resolvemos". Defer isolated technical failures, record them honestly and advance independent eligible tasks; never waive dependencies or falsely complete failed acceptance.
- S6: "si me parecen bien las dos, aunque como un modlo es lo de importar y exportar reportes, la idea seria empezar como los datos inciales con una importacion, osea es una opcion, entonces ademas de lo que dijiste que tambien se pueda asi como lo de importar, esten las dos opciones." D02 supports manual or imported dated opening balances and negative warnings, outside profit/flow. D03–D08 approved answers and context are recorded in L16. "Nada, todo gratis" and "Si asi esta bien" approve the free daily/seven-day/Admin-owned recovery objective, not unproven guarantees or paid/remote operations.

## Tasks

- W0 | S1–S3 | inline | VERIFIED | D01 propagated to scope, financial records/reporting/sync, task fixtures and visual reference note; P0 state recorded. Commit: absent.
- W1 / T1.1 | S1,S3 | inline | VERIFIED | Buildable React/TypeScript/Vite workspace, domain package import, Spanish nonfinancial scaffold and quality scripts. RED missing App observed; GREEN 1 test/build/types/lint/format/HTTP smoke. Independent targeted recheck resolved all observations. Risk: item 5 (new dependencies and build configuration). Commit: absent.
- W2 / T1.2 | S1,S3 | delegated | VERIFIED | Isolation and partial-start cleanup corrections independently rechecked; current unit, disposable DB, browser and quality checks pass. Remote CI remains unverified. Risk: items 1 (existing DB loss) and 5 (test/dependency/CI setup). Implementation: 06feca1; closure: 50be882.
- W3 / T2.1–T2.4 | S1,S3,S4 | delegated | IN_PROGRESS | T2.1 VERIFIED and published; tenant RLS, linked Auth memberships, guarded role RPCs and last-Admin concurrency proved. T2.2 remains PARTIAL in a separate unintegrated worktree; T2.3/T2.4 blocked by dependencies and D08/D05. T2.1 commit: 928329c.
- W4 / T3.1–T3.7 | S1–S3,S5,S6 | inline | IN_PROGRESS | T3.1 VERIFIED after independent TypeScript/PostgreSQL parity and existing DB-suite controls; T3.2 posting is next, then T3.3 corrections. Later sync retains access/storage dependencies. T3.1 commit: this work unit.
- W5 / T4.1–T4.4 | S1–S3 | inline | UNSTARTED | Operational forms including expenses, history, reconciliation and reports. Commit: absent.
- W6 / T5.1–T5.3 | S1–S3 | inline | UNSTARTED | Guarded workbook import/export. Blockers include D06. Commit: absent.
- W7 / T6.1–T6.3 | S1–S3 | inline | UNSTARTED | Integrated accessible/offline checks, recovery proof and pilot acceptance. Blockers include D09. Commit: absent.

The existing plan owns individual task acceptance/dependencies; this logbook records implementation intent and current evidence without creating another competing task specification. Route evidence: W0/W1 were inline. W2 used one bounded writer for the accumulated-context handoff. Future independent substantial units may use isolated detached worktrees; never run parallel writers in the same tree or let workers own shared Git integration. A fresh read-only verifier is required for named high-risk surfaces after their own checks. Commits and pushes to develop are authorized by S4; PRs, deployment and stable promotion to main are not.

Forecast: remaining authored lines are unknown. Keep coherent task commits with their tests/docs; the earlier PR-chain plan is superseded by direct develop delivery. T2.1 (tenant/role foundation) and T2.2 (offline shell) are now eligible after T1.2 closure. Parallel implementation uses isolated worktrees with separate edit surfaces; parent owns shared manifests, lockfiles, runners, progress documents and integration.

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

### L11 — published initial snapshot (2026-10-24)

- User requested GitHub delivery with main and develop instead of per-feature branches/PRs and explicitly authorized the existing gh session. Root commit `06feca1` (`chore: initialize finance MVP foundation and test harness`) contains the existing foundation, plan and harness in 52 files. Both remote branches were verified at that commit; develop is active, main is the default. This supersedes the historical no-commit/no-push and chain-policy statements above, not their historical evidence.
- Local agent tooling remains outside the public snapshot through Git-local exclusions. No application source bytes were changed for publication. Format, lint, types, all 10 unit tests, build, plan validation and harness self-check passed. No DB/browser rerun, remote CI PASS or production readiness is implied.
- The user granted T1.2 review before publication. START created its lineage, but its exact returned continuation selected a different empty target. No T1.2 reviewer ran and no approval was issued. The user chose to stop at that point; no report, decline, reset, repair or review-mode change occurred. L10's pending-consent wording is historical, not the current blocker.

### L12 — renewed implementation and budget constraints (2026-10-24)

"Listo ahora, quiero que completemos todas las tareas que faltan por hacer, lo ideal seria que pusieras a un agente por cada una haciendolas al mismo tiempo, peor entiendo que algunas se pueden solapar y volverse una combinaicon no deseada entonces esta en tu criterio como hacerlas todas, pero lo que quiero es que orquestes agentes para hacerlas lo mas rapido posibles tu revisaras las tareas y determinaras cuales se podran ahcer al mismo tiempo sin ningun inconveniente. Para los agentes usalos con modelos de terra y de deepseek flash de eepseek no de opencode. Para que los tokens duren mas, no vayas a utilizarlos con modelos que consuman mas tokens. Y el tema de los checks de seguridad pues si hay que hacer correciones pues hazlas, no me pidas permisos que si se ahcen o no, esta bajo tu criterio si se deberian de hacer si son menores y no se necesitan de hacer o si ya tienen un impacto tan gigantesco que cambia la vision del proyecto pues ahi si preguntamelos, pero que sea ya cunado no haya nada mas que hacer. Entonces dale empieza con todo eso, despues de cada tarea completada, ahces un commit y pusheas a develop."

- One Terra exploration worker reconciled the dependency graph and actual source. No expensive-model delegates were launched. `opencode models deepseek` confirms `deepseek/deepseek-flash`; existing general/explore agents are configured to Terra, while named native reviewers are still configured to Sol and cannot be launched under S4. Do not claim that changing a config file hot-reloads agent models.
- T1.2 remains IN_PROGRESS/PARTIAL. Its prior technical corrections are resolved, but its native review blocker is preserved; safe-looking preparation is not task completion. D02–D09 remain OPEN and block only their affected work. Do not infer product decisions or candidate-specific native consent from S4.
- Current read-only checks found Gentle AI 4.2.0 and review enabled by global preference. GitHub Actions is enabled and workflow CI is active, but no runs were returned; remote CI is NOT VERIFIED. No native recovery/decline/retry, configuration change or product implementation occurred.
- Engram persistence is pending: the latest save could not resolve an authoritative OpenCode runtime session. Local files remain authoritative; old full mirrors are stale. Do not invent or register a session identity to work around the failure.

### L13 — resumed implementation and T1.2 closure (2026-10-24)

"no entonces no revises, sabes que descativa esa revisionn como tla, no la usemosmmas en este proyecto"

"ok ahora si sigue con todas las tareas"

- Explicit clone-local RDD disable was executed and read back as off; global preference and old authority were preserved. No native review is required for task closure under the current user preference. Functional verification and named high-risk independent checks remain applicable.
- Engram write and full readback succeeded in the fresh session (observation 178); later state and review-disable preference were also persisted. Earlier persistence failures are historical.
- Fresh Terra reconciliation observed format check, lint, typecheck, build, all 10 unit tests, plan validation (63 links/24 tasks/9 decisions/43 headings), harness self-check, disposable DB harness and one Chromium harness test passing. Parent spot-check: check:plan passed. Existing independent targeted cleanup validation remains the final correction proof; no new review ceremony was launched.
- T1.2 is VERIFIED at local harness scope. Remote CI has not been verified; release, pilot and recovery evidence remain pending, not acceptance claimed by this closure. D02–D09 remain OPEN. Next independent eligible units: T2.1 and T2.2; rollback remains limited to new harness wiring, never stored business data.

### L14 — T2.1 tenant and role foundation (2026-10-24)

- Route: two independent substantial units (access and static shell) were delegated to confirmed Terra agents in separate detached worktrees based on `50be882`; no parallel writers shared a worktree. Parent owns integration and Git. T2.1 covers S1/S3/S4, with migrations, typed roles, real-role fixtures, runner extension and access documentation as one unit. The domain index export was explicitly admitted by the parent before integration.
- T2.1 RED: access DB suite failed without the new businesses table. GREEN: tenant read/write isolation, Operator administration denial, permitted Admin controls and concurrent last-Admin protection passed. Independent verification reproduced helper disclosure to foreign/anonymous callers and orphan Auth memberships; one correction batch bound helper identity, revoked anonymous execution and added the Auth foreign key with regression probes.
- Final independent targeted recheck passed all original blockers: foreign helper results false, anonymous execute denied, nonexistent Auth UUID rejected, denied mutation hashes unchanged, and both concurrent demotion/deactivation retain one active Admin. Candidate checks passed lint, types, format, build, full unit suite (4 files/12 tests), runner tests (9), domain test (1), and real disposable `access` and `harness` DB suites. Parent spot-check and integration outcome are recorded in the subsequent handoff.
- No first-Admin production provisioning, signup, business switching, future-table authorization, receipt or financial behavior is claimed. D08 and all other OPEN decisions remain unresolved. Risk: items 2 (authorization), 4 (concurrent last-Admin changes), 5 (DB runner). Rollback disables new RPC entry points and uses forward repair only; never delete memberships/history.
- T2.2 is NOT accepted: original static-shell implementation and two bounded corrections did not pass the retained real server-stopped reload regression; multi-tab update proof remains blocked. Its changes remain only in the isolated shell worktree, not part of this access unit. No further automatic correction loop is authorized by the exhausted proof budget.

### L15 — integrated delivery and pending decision (2026-10-24)

- T1.2 closure `50be882` and T2.1 `928329c` were pushed to `origin/develop`. Parent integrated the isolated access commit and observed lint, typecheck, all 12 unit tests, build, format check and plan check passing on the actual develop tree. Parent also reran the domain fixture (1 test) before integration. Main remains `06feca1`.
- T2.2's second same-blocker correction still produced 1 passing/1 failing/1 skipped shell run; no successful final lint/types/full-suite proof exists for those latest shell bytes. Preserve its worktree and verifier traces for a user-authorized targeted diagnosis. Do not silently publish, abandon or reset it.
- Remaining full tasks are dependency- or decision-blocked: T2.3 needs T2.2/D08; T2.4 needs T2.3/D05; T3.1 needs D02/D07, and later financial/exchange/release tasks retain their recorded gates. No product policy, remote CI result, deployment or pilot acceptance has been inferred.

### L16 — approved policies and independent-work continuity (2026-10-24)

- The exact latest continuity request is preserved in S5. Defer the existing isolated T2.2 failure; do not retry it or block independent domain/server work. Future unresolved technical failures are recorded without false task completion, and presented when no eligible work remains.
- D02: user accepted dated Administrator-defined cash/bank opening amounts and negative balances with warnings; explicitly added manual OR import initialization (exact response in S6). Initial balances are not sales/profit/period flow. Evidence: observation 243.
- D07: "me parece bien asi" approved integer unit-sales quantities, weight/volume purchases up to three decimals and exact whole-COP products or rejection without rounding (244).
- D03: "Me parece bien" approved America/Bogota, Monday-to-Sunday weeks, original-movement-day correction effects with actual correction audit retained (245).
- D04: "Si asi me parece bien" approved Administrator-only posted corrections with reason; Operators edit only owned never-sent records and unknown outcomes remain frozen (246).
- D05: after discussing why client time cannot prove creation before revocation, "Si dale me parece bien asi como tu dices" approved online bootstrap, 24-hour offline validation, logout retention/isolation and explicit Admin incorporation review for revoked-user pending records. Keep original author and approver audit; no timestamp-based authorization, no attention entries in totals, resolve unknown receipts first (248).
- D06: "Me parece bien todo eso" approved selected valid-row imports after preview with visible errors, durable per-row outcomes/resume, also for initial data (249).
- D08: "Si me parece bien asi" approved controlled first Administrator provisioning with secure credential setup and no public signup (250).
- D09: "Nada, todo gratis" and "Si asi esta bien" approve zero cost, daily backup objective, seven-day retention, separate copy, Administrator responsibility, target RPO 24h synchronized data. Free hosting/region and restoration remain evidence-dependent; no remote deployment, account use or paid service is authorized (251–252).
- Register/spec updates record policy approval, not implemented-feature claims. Plan checker now accepts APPROVED decisions while retaining decision/task mapping, DAG, links and incomplete tasks. No financial or pilot acceptance is inferred.

### L17 — T3.1 exact domain implementation in progress

- Route: inline, independent of deferred T2.2. Added canonical signed-64 COP parsing/arithmetic/inverse, integer unit and three-decimal weight/volume line totals, seven distinct account/profit/flow effects, and explicit dated manual/import opening contracts with negative warning indicators. No posting, import UI or baseline persistence is claimed.
- RED observed: money-effects suite could not import the absent domain implementation; new money-runner regression failed before its explicit suite was supported. GREEN: four domain tests, eleven runner/plan tests and shared JSON fixture parity on real authenticated PostgreSQL passed. The additive SQL adapter migration changes no stored financial data. The isolated DB runner started/stopped only its owned project; no root reset.
- Policy validator RED rejected APPROVED decisions; corrected checker preserves mappings/DAG/link checks. Independent check found two stale active P0 phrases; parent corrected those phrases, pending targeted readback.
- Risk: item 3 (shared exported numeric contracts) and item 5 (suite-runner extension). Final quality checks and independent acceptance remain pending before commit/push. No native RDD operation was run.

- Final T3.1 independent verdict: PASS for S1/S3/S5/S6. Four money tests, eleven runner tests, plan validation, real money/harness/access DB suites and direct domain compilation passed. NULL rejection probe was retained in the committed SQL fixture. Scratch-wide app typecheck failed only from copied workspace symlink resolution; actual project typecheck and build passed, and no scratch result is misreported as full-app proof. All owned Docker resources stopped. No baseline UI/import/persistence/posting acceptance is claimed.
