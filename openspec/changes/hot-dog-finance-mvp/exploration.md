## Exploration: hot-dog-finance-mvp

### Current State
The `micu` workspace has only SDD metadata: no application source, stack, schema, build manifest, tests, or existing OpenSpec domain specifications. `openspec/config.yaml` confirms that strict TDD is disabled solely because no tooling exists. Therefore, this exploration validates product and architecture boundaries; it does not infer implementation conventions.

The MVP is a Spanish-first, offline-capable shared PWA for one known Colombian family hot-dog business. It needs separate email/password accounts, an Administrator/Operator boundary, and cloud synchronization as a recoverable shared record. The configured business is the only usable business in the UI, but data isolation must be tenancy-ready from the first persisted record.

### Affected Areas
- `openspec/changes/hot-dog-finance-mvp/exploration.md` — records the validated MVP boundary and decisions required before later SDD phases.
- `openspec/config.yaml` — establishes the current constraint: no chosen stack or quality tooling.
- Future application data layer — must isolate every business-scoped record, preserve posted money records, and coordinate local/offline and cloud state.
- Future PWA synchronization layer — must queue, retry, deduplicate, and surface conflicts without preventing daily operation.
- Future reporting and import/export layer — must derive summaries from the same retained records rather than separate totals.

### Approaches
1. **Offline-first PWA with a custom API and relational cloud database** — Store an encrypted-or-device-protected local database plus an outbox in the PWA; synchronize to a server API that enforces identity, roles, tenant isolation, and reporting persistence.
   - Pros: Explicit control of financial-record rules, imports/exports, audit retention, and future multi-business evolution; portable relational reporting model.
   - Cons: Highest initial effort; offline synchronization, authentication, and operational hosting must be built and verified.
   - Effort: High

2. **PWA with managed authentication/database services and an application sync boundary** — Use managed identity, relational storage, row-level isolation, and possibly storage/functions, while retaining an explicit local store and sync contract in the client.
   - Pros: Faster authentication, hosting, backups, and server-side isolation; less infrastructure work for an MVP.
   - Cons: Offline behavior, conflict handling, export/import, and provider limits still require application design; potential service coupling.
   - Effort: Medium

3. **Local-first synchronization platform behind the PWA** — Adopt a product that replicates a local client database to cloud storage and exposes conflict/sync primitives.
   - Pros: Strongest fit for disconnected operation and cross-device convergence; may reduce custom outbox code.
   - Cons: Vendor/model constraints, financial-audit fit, server-side reporting, access rules, and future migration must be proven before commitment.
   - Effort: Medium

### Recommendation
Proceed to proposal only with an architecture-neutral product boundary: an offline-first PWA, server-authoritative identity/role/tenant access, immutable-or-reversible posted financial events, and derived reporting. Do not select a technology stack in exploration. The later stack/design phase should run a short proof against the three approaches using these decision criteria: reliable offline writes and recovery, idempotent sync, Spanish PWA usability, tenant/role enforcement, relational reporting, Excel round-tripping, backup/export ownership, operating cost, and an exit path.

The core concepts should be:

| Concept | MVP boundary |
|---|---|
| Business tenant | One configured business is visible, but every business-scoped record carries a tenant identifier and is filtered/enforced server-side. Self-service setup and business switching are deferred. |
| Member and role | Individual email/password account; Administrator manages the configured business and operator access, Operator records day-to-day activity. Granular permissions are deferred. |
| Catalog product | Flexible sellable item with active status, name, optional description/category, and default price. A sale line snapshots the selected product name and actual unit price. |
| Sale | One operational sale with multiple item lines and exactly one payment method: cash or transfer. Each line may override the current default price with a recorded reason/note policy chosen later. Split payments, receipts, invoices, and customer records are deferred. |
| Supplier purchase | A purchase with itemized supplier lines, quantities, and actual costs. It records spending but does not automatically update stock or calculate inventory. |
| Money movement | Contribution, owner withdrawal, and bidirectional cash/bank transfer are distinct, auditable record types. A transfer has one source and one destination and must not alter total funds. |
| Reconciliation | Daily cash or bank observation compares expected activity-derived balance with observed balance and requires a note when different. It records the difference; it must not silently create a balancing transaction. |
| Audit and correction | Posted records retain actor, device/client time, server receipt time when available, and change/correction history. Avoid hard deletion; use void/reversal/correction semantics so reports can exclude invalid records while audit history remains. |
| Summary and exchange | Daily/weekly/monthly summaries are derived from retained records. Excel import requires mapping, validation preview, source metadata, and duplicate protection; export is a user-owned portable data copy. |

Offline and synchronization implications:

- Client-created records need stable globally unique IDs, operation IDs, sync status, retry behavior, and idempotent server acceptance. A repeated upload must not duplicate a sale or transfer.
- Financial entries should be append-only after posting. This reduces cross-device conflicts; catalog edits, member/role changes, and same-account/same-day reconciliation drafts need version checks and a visible resolution path.
- Sales and purchases must snapshot applied names, prices, quantities, and payment/account facts so later catalog edits do not rewrite history.
- The PWA must clearly distinguish saved locally, pending cloud sync, synced, and sync-needs-attention states. Offline use is supported; sole-device data loss before synchronization remains a documented risk.
- Server-side authorization and tenant scoping remain mandatory after sync. The local cache is a convenience copy, not a permission authority.

Migration implications:

- Start with tenant IDs, actor IDs, immutable record IDs, audit metadata, and type/version fields in the initial schema even though only one business is configured.
- Historical wording corrected: represent Colombian money as exact integer whole COP, NOT centavos/minor units (`MoneyCop = bigint`, canonical decimal strings at JSON boundaries); show COP-formatted amounts in Spanish. See the later [exact money contract](design.md#exact-money-and-quantities) for signs, ranges and overflow. Unsupported fractional COP is rejected without silent rounding; quantity scale remains OPEN D07.
- Version both local-store schema and cloud schema. Migrations must be resumable, backward-compatible across temporarily offline clients, and protected by export/backup before destructive changes.
- Imports need a staging/mapping path, row-level validation results, duplicate keys/source batch identity, and an audit trail. Imports must not bypass normal tenant, actor, and money-validation rules.

### Risks
- Offline writes on multiple devices can conflict, especially catalog changes and same-day reconciliation; unresolved conflicts can undermine trust in balances.
- Treating corrections as edits or deletions can corrupt previously viewed summaries and weaken auditability.
- Transfers, payment classification, and reconciliation differences can be double-counted unless reports derive from a single, explicitly typed movement model.
- Excel imports are an integrity and security boundary: malformed dates, locale-specific numbers, duplicates, and unauthorized data must be rejected or previewed safely.
- A managed or local-first provider may simplify delivery but can constrain audit querying, export ownership, offline guarantees, or future migration.
- The 400-line review budget will require implementation slices; the future tasks phase should forecast chained PRs before apply.

### Ready for Proposal
Yes — the validated MVP and non-goals are sufficiently bounded for a proposal. Tell the user that the proposal can commit to the Spanish-first one-business MVP and its operational records, while the design phase must still choose a stack after an offline/sync proof and explicitly define correction, reconciliation, and import validation rules.

### Subsequent review and supersession

The preceding approach comparison and readiness statement are historical exploration, not current implementation approval. [design.md](design.md) now proposes React 19/TypeScript/Vite, Dexie/IndexedDB and Supabase Auth/Postgres/RLS/functions; no offline/sync proof has run. Shared cloud service remains REQUIRED. The earlier local encrypted-or-device-protected description is an explored option, not an IndexedDB encryption guarantee. Price override is supported without an approved mandatory-note rule.

At review time D01–D09 were OPEN. The user subsequently selected “Incluir gastos operativos”: [D01 is now APPROVED](design.md#decision-register), adding operating expenses and deducting them from estimated profit. D02–D09 remain OPEN: baseline/negative balances, calendar/correction dates, correction permissions, offline/shared-device/logout, import acceptance atomicity, quantity scale, first Admin provisioning and pilot operations. Do not infer other settled choices from exploratory prose. The current [tasks](tasks.md) replace the earlier six-slice guess with stable dependency-gated work units and resumable evidence. Existing PNGs show foundations/components, not operational screen validation; operational captures are PENDING. Portable Excel is not full backup recovery; sole-device unsent/evicted records remain unrecoverable from cloud backup.
