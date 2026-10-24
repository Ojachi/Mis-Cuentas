# Business Access Specification

## Requirements

### Requirement: Single-business membership boundary

The system MUST preconfigure the first active Administrator through controlled provisioning under approved D08 in the [decision register](../../design.md#decision-register), with secure credential setup and no committed secrets. Public onboarding, business switching, and roles beyond Administrator/Operator SHALL NOT exist. Every member MUST authenticate individually with email/password. Administrators MUST manage memberships and retain one active Administrator. Every business record MUST be tenant-bound and server-authorized: Administrators manage access, catalog, imports, reconciliations and exports; Operators create records. Members MAY edit only their own drafts/never-sent pending payloads; possibly-sent payloads MUST freeze. Approved D04 restricts posted linked corrections to active Administrators with a reason; draft ownership does not confer that authority.

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

First sign-in and bootstrap MUST require online authentication. Every server surface MUST enforce current tenant membership and permission, never a cached browser role. Approved D05 limits offline access to 24 hours since last online authorization validation. Local cache, documents, outbox and cursors MUST be user/business-partitioned; logout hides the partition without deleting unsent data, recoverable only by its original user after reauthentication. Another member MUST NOT read or replay it. Revocation MUST retain server time, actor and changed permission, and deny unauthorized server activity; immediate offline revocation cannot be promised. Forbidden pending records remain attention, excluded from money totals. An active authorized Administrator MAY explicitly approve their incorporation through a server-validated audited resolution preserving original author and approving actor/time. Client timestamps are evidence, not retroactive permission. Unknown outcomes resolve before a linked new attempt; accepted facts remain valid.

#### Scenario: Isolate a shared device
- GIVEN user A has cached data and an unsent sale
- WHEN user B authenticates on the same device
- THEN B cannot read or replay A's partition and A's unsent sale is not silently deleted

#### Scenario: Recheck a revoked role
- GIVEN a cached Operator role and a remotely revoked membership
- WHEN a push, pull or receipt lookup reaches the server
- THEN the server denies access without posting or leaking data, and the client preserves the unsent attempt for explicit resolution
