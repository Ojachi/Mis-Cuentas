# Financial Reporting and Exchange Specification

## Requirements

### Requirement: Explainable Spanish COP summaries

The system MUST present tenant-scoped day/week/month summaries in Spanish-first Colombian peso (COP) formatting. It MUST distinguish cash flow (cash/bank movements), estimated profit (record-derived sales/costs), and reconciliation differences; a difference MUST NOT be treated as profit or cash flow.

#### Scenario: Explain a monthly period
- GIVEN sales, costs, a transfer, and a discrepancy
- WHEN an Administrator views the month
- THEN all three figures are explained separately

### Requirement: Guarded Excel exchange

Excel import MUST map columns, preview and validate every row before confirmation, retain source/batch audit metadata, and prevent duplicates. Invalid/duplicate rows MUST be identified without silent import. Approved D02 supports optional opening-balance initialization through this import path as well as manual entry; imported baseline amounts/date are distinct from sales and profit and MUST NOT duplicate an existing baseline. Export MUST provide portable retained records. Other currencies and destructive import replacement SHALL NOT be supported.

#### Scenario: Preview and repeat an import
- GIVEN a mapped workbook with valid, invalid, and prior rows
- WHEN preview and confirmation run
- THEN each row is accepted/rejected/duplicate and audit is retained

### Requirement: Operation-derived totals and periods

Reports MUST use the [operation effects table](../../design.md#operation-effects-and-reporting). Estimated profit is sales minus purchases minus operating expenses, not formal accounting profit; those spending categories remain distinct. Contributions/withdrawals do not affect profit; combined flow is sales − purchases − expenses + contributions − withdrawals, and transfers net to zero. Available funds require explicit cash/bank opening balances plus cumulative deltas, not an assumed zero. D02 allows negatives with warnings and manual/imported dated opening balances outside profit/period flow. D03 uses America/Bogota, Monday weeks and original-day correction attribution while retaining actual correction audit timestamps. Rejected/attention/draft records MUST NOT enter confirmed totals; labeled local overlays MUST be replaced once by receipt/pull identity. Excel MUST preserve operating-expense type/description/amount/account and distinguish opening data from transactions.

#### Scenario: Separate profit from funds
- GIVEN a test-only zero baseline, sale 36000, purchase 12000, operating expense 3000, contribution 10000, withdrawal 4000, internal transfer 8000 and observation difference −2000
- WHEN confirmed totals are calculated
- THEN combined flow is 27000, estimated profit is 21000, transfer net is zero and the discrepancy changes neither total

#### Scenario: Replace provisional totals on acknowledgement
- GIVEN a local queued sale included once in a labeled provisional view
- WHEN its acknowledgement and later pull deliver the same accepted fact
- THEN it contributes once to confirmed totals, no longer appears as a provisional duplicate, and a rejected operation contributes nothing

### Requirement: Bounded typed Excel posting

Import MUST enforce declared tested limits on workbook bytes, sheets, rows, columns, cell length and expanded content before unsafe parsing. It MUST reject encrypted/macro-enabled/unsupported files and formulas in mapped fields, never executing formulas or trusting cached formula results. COP, quantities and dates MUST follow explicit typed formats, exact validation and current server permissions. Approved D06 confirms only selected valid rows, each independently atomic; invalid/unselected rows remain unimported with visible reasons. Preview and explicit confirmation are required, also for initial data imports.

Every accepted row MUST atomically retain facts, audit and receipt. Stable persisted batch/row operation identity and receipts MUST make interruption/retry safe without reposting successful rows. File hash alone MUST NOT be claimed to detect the same business row in a different file: use durable source IDs where present and flag normalized-content candidates for explicit review otherwise, preserving legitimate identical transactions.

#### Scenario: Resume an interrupted confirmation
- GIVEN stable identities for rows A and B and a persisted success receipt for A
- WHEN confirmation loses connection before B's outcome is known and is retried
- THEN A is not reposted, B resolves using its same operation identity, and visible outcomes respect the chosen D06 atomicity

#### Scenario: Reject an unsafe workbook and flag copied rows
- GIVEN an oversized workbook, a mapped formula, or a new workbook containing an already imported source record ID
- WHEN validation/preview runs
- THEN unsafe input is rejected without execution and the copied source row is flagged even if the file hash differs

### Requirement: Portable export and recoverable backup

Exports MUST preserve retained records and exact numeric/date meaning while encoding untrusted text safely against formula injection. XLSX exchange is NOT a full database/Auth/schema/policy/receipt backup. D09 requires free infrastructure only, daily backup objective, seven-day retention, a separate copy, Administrator responsibility and target RPO 24 hours of synchronized data. Free host/region feasibility and a full isolated restore MUST be demonstrated before pilot; these objectives are not guarantees. Recovery MUST preserve newer accepted history and device queues; sole-device unsent data is outside server backups.

#### Scenario: Export safely and restore independently
- GIVEN untrusted item text beginning with `=` and accepted records plus unsent local records
- WHEN an export is opened and the separate backup restore drill runs in isolation
- THEN text does not execute, exact values round-trip, full restoration is verified from backup rather than XLSX, and live history/queues remain untouched
