# Offline Financial Sync Specification

## Requirements

### Requirement: Safe offline financial writes

Sales, supplier purchases, operating expenses, owner contributions, owner withdrawals, and cash-to-bank and bank-to-cash transfers MUST each be creatable offline with stable identity and local, pending, synced, or attention status. A shared online service is REQUIRED for confirmed shared history. The system MUST retry pending submissions and apply an accepted identity exactly once. Members MAY edit only their own drafts/never-sent pending payloads; possibly-sent operations MUST freeze before first send. Historical records already synced to cloud MUST NOT be edited while offline. Acceptance MUST recheck tenant, role, and validation; rejected, stale, or conflicting records MUST become attention with an actionable reason, never silently overwritten or resolved.

#### Scenario: Create every supported operation offline
- GIVEN an Operator is offline with cash and bank accounts available
- WHEN the Operator creates a sale, supplier purchase, operating expense, contribution, withdrawal, cash-to-bank transfer, and bank-to-cash transfer
- THEN each record is stored locally with stable identity and a pending status

#### Scenario: Synchronize a retried sale
- GIVEN a valid offline sale
- WHEN sync submits it repeatedly after reconnection
- THEN its effect exists exactly once and status is synced

#### Scenario: Flag unsafe acceptance
- GIVEN a changed role, invalid record, or conflict
- WHEN synchronization evaluates it
- THEN it remains visible as attention without a posted overwrite

#### Scenario: Protect synced history while offline
- GIVEN a historical record has already synced to cloud
- WHEN a member attempts to edit it while offline
- THEN the system denies the edit and leaves the historical record unchanged

Approved D05 permits offline access for at most 24 hours after online authorization validation and retains user-isolated unsent records on logout. Revocation is audited with server time and actor. Operations forbidden on reconnect MUST remain attention outside financial totals until an authorized Administrator explicitly approves server-validated incorporation with original-author/approver audit. Claimed offline timestamps MUST NOT automatically authorize pre-revocation acceptance; possibly-sent unknown outcomes resolve before a new linked attempt. The MVP MUST NOT promise recovery from a lost unsynchronized sole device.

### Requirement: Frozen identity and receipt resolution

The client MUST persist frozen canonical payload/schema version/hash and operation key before first send. Timeout MUST retain the same identity/payload and resolve via authenticated receipt/retry before any editing or new submission. Same tenant/key/hash MUST return the same outcome; hash mismatch MUST reject without posting. Transient network/server/rate-limit errors MAY retry with bounded backoff; expired auth MUST pause for sign-in; permanent validation/role/version conflicts MUST show attention. A corrected new attempt after definitive rejection MUST retain linkage to the rejected audit, not overwrite it. Mutable metadata conflicts MUST use versions, not last-write-wins; immutable posted records require linked corrections.

#### Scenario: Resolve a lost acknowledgement
- GIVEN the server committed a sale but the response timed out
- WHEN the user tries to edit and two tabs replay the frozen operation
- THEN editing is blocked, retries use the original key/hash, and only the original receipt and single sale effect exist

### Requirement: Atomic persistence and complete pull

Local document/outbox/provisional projection MUST commit together before saved feedback. Server facts/audit/receipt MUST commit together per operation. Local acknowledgement/projection and each pulled fact page/cursor MUST commit atomically with identity-based replay. Pull MUST use a committed safe watermark; allocation sequence alone MUST NOT skip a lower-sequence transaction committed later. Every writer MUST participate in the commit-safe ordering protocol. Multi-tab replay MUST coordinate but server idempotency MUST remain correct after leader crashes or lease races.

#### Scenario: Retain a failed local form
- GIVEN a completed form and IndexedDB quota/abort/commit failure
- WHEN saving is attempted
- THEN the form values and actionable error remain, no saved message is shown, and no orphan document/outbox entry exists

#### Scenario: Restart a pull without skipped facts
- GIVEN delayed transaction A, competing transaction B and a crash before a local page/cursor commit
- WHEN A/B commit and pull resumes from its retained cursor
- THEN every committed fact eventually appears once, aborted facts never appear and cursor advancement skips no committed change

### Requirement: Offline-ready shell and outbox-safe upgrades

The PWA MUST cache a minimal installable static shell/navigation fallback and indicate readiness only after first online authentication/bootstrap and usable local storage/assets. Service workers MUST NOT indiscriminately cache authenticated API responses. Client/schema upgrades MUST preserve unsent records, stable hashes, receipts and supported old-client replay; unsupported versions MUST show upgrade-required without data deletion. Blocked IndexedDB upgrades MUST identify other tabs to close/reload. Worker activation/reload MUST wait for a compatible safe handoff, not interrupt local transactions. Eviction/private mode/sole-device loss remain explicit limits; persistence requests are best effort.

#### Scenario: Upgrade with an old frozen outbox
- GIVEN an old client with an unsent/frozen operation and another tab blocking an upgrade
- WHEN the new client/worker is offered
- THEN blocked-upgrade guidance is visible, activation waits safely, and the operation retains its identity/hash for compatible replay or explicit upgrade attention

#### Scenario: Reopen an initialized device offline
- GIVEN online sign-in/bootstrap, cached shell and an offline session permitted by D05
- WHEN the installed PWA is reopened offline
- THEN the shell and permitted partition load without network dependency, while a first uncached visit does not claim offline readiness
