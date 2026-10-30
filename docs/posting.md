# Financial Posting

`post_financial_operation(business_id, operation_id, payload)` is the only writer for accepted financial facts. It requires the current authenticated active member, keeps facts/effects/audit/receipt in one transaction, and serializes each business with its row lock. Operators may post; only later correction work will require Administrator.

Payload version `"1"` uses explicit canonical JSON: known ASCII field names sort by byte order, arrays retain submitted order, strings use JSON escaping, and separators are `", "` and `": "`. This is NOT raw PostgreSQL object serialization order. TypeScript and SQL share a pinned Unicode/escape SHA-256 fixture. All money and quantities are strings; numbers, missing/null required fields, irrelevant fields, invalid accounts/kinds and malformed snapshots reject. The server derives and hashes canonical bytes itself.

`occurredAt` and `clientCreatedAt` require explicit timezone offsets and are retained separately from server `accepted_at`; these claimed times never authorize a revoked user. Membership is held through the posting transaction. A purchase line may specify `measure` as `unit`, `weight` or `volume` (default `unit`); sales are by unit. Fractional purchases still require whole-COP products, with no rounding.

Example:

```json
{
  "account": "cash",
  "amount": "24000",
  "clientCreatedAt": "2026-10-24T12:01:00-05:00",
  "kind": "sale",
  "lines": [
    {
      "name": "Hot dog",
      "quantity": "2",
      "total": "24000",
      "unitPrice": "12000"
    }
  ],
  "occurredAt": "2026-10-24T12:00:00-05:00",
  "version": "1"
}
```

The `amount` of itemized sales/purchases is derived from validated immutable line snapshots, not trusted from the payload. Reusing a business/operation key with identical canonical bytes returns its existing authenticated receipt; different bytes reject without mutation. RLS permits active members to read only their tenant and denies direct writes or changes to accepted history.

Run `npm test -- posting` and `npm run test:db -- posting`. The disposable DB suite covers all seven kinds, canonical replay/hash mismatch, table-specific tenant/direct-DML/anonymous denials, malformed payload state invariants, injected second-transfer-leg rollback and two real competing sessions producing one identical receipt. Failure injection exists only in owned test fixtures, never the production RPC. Rollback disables new callers or uses forward repair; never drop stored facts or reset live data.
