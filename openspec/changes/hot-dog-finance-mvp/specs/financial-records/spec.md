# Financial Records Specification

## Requirements

### Requirement: Auditable finance records

Administrators MUST manage catalog prices. Sales MUST retain item, quantity, price snapshot/override, and one-or-more lines paid entirely by cash or transfer. Purchases MUST retain supplier and itemized lines. Operating expenses MUST retain description, positive COP amount and paying account; examples include gas, transport and rent. They MUST decrease that account and estimated profit, remain distinct from purchases, and MUST NOT be confused with owner withdrawals or counted twice. Cash↔bank transfers MUST make equal opposite account changes; contributions increase and withdrawals decrease the selected account. Reconciliations MUST retain expected, observed, difference, account, period, and note without a balancing movement. Posted records MUST retain immutable ID, actor, timestamps, and linked correction, void, reversal, or deletion-attempt audit; hard deletion MUST NOT occur.

#### Scenario: Record normal operations
- GIVEN catalog prices and cash/bank accounts
- WHEN an Operator posts an itemized transfer sale, purchase, operating expense for gas, and transfer
- THEN applied prices, supplier, expense description and account effects are retained; the expense reduces its account and estimated profit once while the transfer remains neutral overall

#### Scenario: Reject or correct safely
- GIVEN a split/empty sale, discrepancy, or wrong posted purchase
- WHEN it is submitted, reconciled, or corrected
- THEN invalid sales are rejected; reconciliation changes no balance; history remains auditable

The MVP SHALL NOT automate inventory, customers, invoices, receipts, or multi-currency.

### Requirement: Exact COP and quantity snapshots

Money MUST use exact whole-COP integers (`MoneyCop = bigint`) and canonical decimal strings at JSON/API boundaries, consistent with [exact money and quantities](../../design.md#exact-money-and-quantities). Browser and server MUST reject malformed signs, decimals, signed-64 overflow and unrepresentable products/sums/inverses without floating point or silent rounding. Entered amounts, prices, costs and quantities MUST be positive. Approved D07 requires integer unit-sale quantities and up to three decimal places for weight/volume purchases; fractional-COP products MUST reject. Approved D02 allows Administrator-defined cash/bank opening balances and effective date, entered manually or imported, and negative resulting balances with warning. Opening balances MUST NOT become sales/profit, and unknown opening funds MUST NOT silently default to zero.

Sales MUST snapshot item name, exact quantity, actual unit price (including visible override) and line total; purchases MUST snapshot supplier, item description, quantity, unit cost and line total with selected account. Catalog changes MUST NOT rewrite either history. A mandatory price-override reason is not established by this specification.

#### Scenario: Reject unsupported precision and overflow
- GIVEN inputs `1.5` COP, `1e3`, `+1`, `01`, `-0`, an out-of-range integer or a line product overflowing signed 64-bit storage
- WHEN either client or server validates the record
- THEN the entire operation is rejected without rounding, partial posting or a false saved status

### Requirement: Atomic linked correction

Accepted originals MUST remain immutable. Void MUST append a linked exact inverse; replacement MUST append inverse plus validated replacement atomically with audit and receipt. Retain target/replacement/group identities, required reason, actor and timestamps. Original and inverse net to zero before replacement effects. Hard delete and in-place updates MUST be denied and audited distinctly. Approved D04 allows only active Administrators to correct posted history. Approved D03 attributes corrections to the original movement's reporting day in America/Bogota while recording actual correction time; historical derived reports can change, not retained cutoff observations.

#### Scenario: Correct once under retry and concurrency
- GIVEN an accepted purchase of 12000 COP and a permitted replacement of 15000 COP
- WHEN two different correction requests target the same revision and one request is retried
- THEN only one inverse/replacement group commits, the retry returns its original receipt, the competing request becomes attention, and net purchase cost is 15000 COP

#### Scenario: Roll back a failed replacement
- GIVEN an accepted sale and a correction whose replacement fails validation
- WHEN the server processes the correction
- THEN no inverse, replacement or success receipt commits and the original effects remain

### Requirement: Retained reconciliation observation

Reconciliation MUST retain observed amount/time, expected snapshot, difference, account, period, actor, nonzero-difference note and calculation cutoff (confirmed watermark plus included local IDs if provisional). It MUST NOT post money. Later accepted facts/corrections MUST NOT invisibly rewrite the retained snapshot; a new current comparison MUST be separately labeled or a linked observation appended. Baseline/calendar behavior MUST follow approved D02 and D03, including negative warnings and original-day correction attribution.

#### Scenario: Preserve a prior cutoff
- GIVEN expected cash 328000, observed cash 326000 and a retained cutoff
- WHEN a late sale arrives after that observation
- THEN the original −2000 difference and cutoff remain visible, any current comparison is labeled separately, and no balancing entry is created
