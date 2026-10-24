# Exact money and opening balances

All API money is a canonical decimal string of whole COP within signed 64-bit storage. The domain uses `bigint`; PostgreSQL adapters validate text before casting. Positive operation amounts reject zero, signs, whitespace, scientific notation and fractional pesos. Arithmetic, products and reversals reject overflow instead of rounding.

Unit sales use positive integers. Weight/volume purchase quantities support up to three decimals; quantity times unit price must produce whole COP. The same JSON fixtures exercise TypeScript and the authenticated PostgreSQL adapter through `npm test -- money-effects` and `npm run test:db -- money`.

The seven effects remain distinct: sales increase profit; purchases and operating expenses decrease it; contributions and withdrawals affect funds, not profit; cash/bank transfers net to zero. Opening balances are explicit dated cash/bank values with manual or import provenance, not sales/profit/period cash flow. Negative balances are valid and return a warning indicator. These are validation contracts, not a completed opening-balance screen, import flow or posting service.

The additive SQL functions do not store or mutate financial history. Posting, authorization, idempotency receipts and correction transactions belong to later tasks. Keep existing data on rollback; disable callers or repair forward rather than resetting a database.
