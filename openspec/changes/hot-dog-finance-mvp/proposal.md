# Proposal: Hot Dog Finance MVP

## Intent

Give a Colombian family hot-dog business a Spanish-first shared finance record, replacing fragile spreadsheets and memory with recoverable daily records and cash/bank visibility.

## Scope

### In Scope
- One configured business with email/password Administrator and Operator roles; every record is tenant-scoped from inception, but switching is unavailable.
- Journeys: Admin manages access/catalog and imports Excel; Operator posts offline sales (lines; cash **or** transfer), purchases, operating expenses (including gas, transport and rent), contributions, withdrawals, and cash/bank transfers; Admin reviews summaries, reconciles observations, and exports data. Estimated profit deducts both purchases and operating expenses, never owner withdrawals.
- Offline creation with visible local/pending/synced/attention status, retry, idempotent sync, and server-side role/tenant enforcement.
- Auditable posted history: actor and timestamps, immutable IDs, sale snapshots, and void/reversal/correction—not hard deletion. Reconciliation records noted differences without creating a balancing entry.
- Excel mapping, preview, row validation, source/batch metadata, duplicate protection, and portable export; COP is Spanish-formatted.
- A REQUIRED shared online service is authoritative for accepted facts. Offline is a device-owned queue/cache with provisional visibility, not local-only operation or an alternative to synchronization. First authentication/bootstrap requires connectivity.

### Out of Scope
- Multiple usable businesses, onboarding, switching, granular permissions, multi-currency, customers, invoices/receipts, split payments, or inventory/stock automation.
- Silent conflict resolution, destructive history edits, or loss protection for a sole device before it synchronizes.

## Capabilities

### New Capabilities
- `business-access`: tenant-ready one-business membership and Administrator/Operator access.
- `financial-records`: catalog, posted sales, purchases, money movements, corrections, and reconciliation.
- `offline-financial-sync`: offline writes, status, retry, idempotency, and conflict attention.
- `financial-reporting-exchange`: derived summaries plus Excel import/export safeguards.

### Modified Capabilities
None — no existing OpenSpec capabilities exist.

## Approach

The earlier architecture-neutral proposal is now refined by [design.md](design.md): proposed React 19/TypeScript/Vite PWA, Dexie/IndexedDB and Supabase Auth/Postgres/RLS/functions. This selection is a planning proposal, not a proven offline/sync implementation. Validate it through [tasks.md](tasks.md), starting with workflow prerequisites, auth/tenant foundation and the minimal offline shell before financial offline E2E. Preserve the user-selected `auto-chain` / `feature-branch-chain` with `develop` as integration/tracker.

Readiness is conditional: [D01 is approved and D02–D09 remain OPEN](design.md#decision-register). The user explicitly included operating expenses in the MVP. P0 routes remaining decisions; safe scaffold/auth schema/static shell work can proceed after workflow prerequisites, while affected policy work remains blocked. No blanket approval, runtime evidence or fully implementation-ready claim is implied.

## Affected Areas

| Area | Impact | Description |
|---|---|---|
| `openspec/changes/hot-dog-finance-mvp/specs/` | Refine | Four change-local capability specifications; promotion to canonical specs is future work. |
| Future client, sync, and data layers | New | Product implementation after design approval. |

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Duplicate/conflicting offline records | Medium | Stable IDs, idempotency, visible resolution. |
| Misleading balances | Medium | Typed movements, derived totals, reconciliations. |
| Unsafe Excel data | Medium | Staging preview, validation, audit trail. |

## Rollback Plan

Verify portable export and full backup/restore separately before rollout. XLSX is not a full restorable database/Auth/schema/policy/receipt backup. Roll back by disabling incompatible writers/features while preserving facts, audit, receipts and local queues, using compatible deployments/forward migrations. Any disaster restore requires a tested backup, fenced writers and an explicit plan for newer accepted facts; never silently replace business history or queues, and never perform destructive schema rollback.

## Dependencies

- Exact technical contracts in [design.md](design.md), matching specifications and observed implementation proof in [tasks.md](tasks.md).
- D01 is approved: include operating expenses. OPEN D02–D09: opening baseline/negative balances; calendar/correction dates; correction permissions; offline/shared-device/logout; import atomicity; quantity scale; first Admin provisioning; pilot hosting/backup RPO/owner. The central register maps each to blocked task IDs.
- The earlier no-Git/no-scaffold observation is historical. Current repository/tooling evidence lives in [tasks.md](tasks.md). Historical missing `sdd-attempt` support must be rechecked if an SDD execution route is selected; direct implementation does not invoke an SDD phase or claim that tooling issue is fixed.

## Success Criteria

- [ ] Initialized, authenticated pilot devices create all seven operation types offline under the approved session policy; accepted records appear exactly once after reconnecting. Sign-in/bootstrap, access management and server-confirmed import/correction/export workflows require connectivity; no blanket claim that all journeys work offline.
- [ ] Summaries/reconciliations are explainable from retained records; invalid entries remain auditable.
- [ ] Each Excel-import row is accepted or rejected, and exported data is user-owned.
- [ ] Policy decisions are recorded, every task has observed acceptance evidence, full backup/restore is proven separately from XLSX export, and sole-device unsent loss remains an explicit limitation.
