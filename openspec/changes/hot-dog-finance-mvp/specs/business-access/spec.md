# Business Access Specification

## Requirements

### Requirement: Single-business membership boundary

The system MUST preconfigure the first active Administrator; provisioning mechanism is OPEN D08 in the [decision register](../../design.md#decision-register). Public onboarding, business switching, and roles beyond Administrator/Operator SHALL NOT exist. The system MUST authenticate every Administrator and Operator account individually with that account's email and password before granting access. Administrators MUST manage membership and retain one active Administrator. Every membership and business record MUST be tenant-bound and server-authorized: Administrators manage access, catalog, imports, reconciliations, and exports; Operators create records. Members MAY edit only their own drafts/never-sent pending payloads; possibly-sent payloads MUST freeze. Posted history MUST use linked correction; server correction permissions remain OPEN D04, not implied by draft ownership.

#### Scenario: Authenticate an individual member
- GIVEN an Administrator or Operator has a valid individual email and password
- WHEN that member signs in
- THEN the system grants only that member's role- and tenant-scoped access

#### Scenario: Reject invalid authentication
- GIVEN an Administrator or Operator account
- WHEN an incorrect email or password is submitted
- THEN the system denies access without exposing data

#### Scenario: Create a tenant member
- GIVEN an active Administrator
- WHEN the Administrator adds an Operator
- THEN the Operator is bound to that business

#### Scenario: Deny a boundary violation
- GIVEN a cross-tenant, unauthorized, or last-Administrator change
- WHEN it is requested
- THEN the system denies it without exposing or changing data

### Requirement: Session and local ownership boundary

First sign-in and initial tenant bootstrap MUST require online authentication. RLS and every write/read RPC MUST enforce current authenticated tenant membership and role, including receipts, pull, imports and corrections. The browser's cached role MUST NOT authorize server actions. Local cache, documents, outbox and cursors MUST be partitioned by user and business; another member signing in on the same device MUST NOT see the prior member's data. Offline expiry/logout/reauthentication and unsent-record handling are OPEN D05. The system MUST NOT silently purge unsent records on logout, switching identity or role loss. Remote revocation MUST fail closed at the server but SHALL NOT be represented as immediate erasure or denial of cached access on disconnected devices.

#### Scenario: Isolate a shared device
- GIVEN user A has cached data and an unsent sale
- WHEN user B authenticates on the same device
- THEN B cannot read or replay A's partition and A's unsent sale is not silently deleted

#### Scenario: Recheck a revoked role
- GIVEN a cached Operator role and a remotely revoked membership
- WHEN a push, pull or receipt lookup reaches the server
- THEN the server denies access without posting or leaking data, and the client preserves the unsent attempt for explicit resolution
