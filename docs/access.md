# Access Foundation

The database has one business membership per authenticated individual. The only roles are `Administrator` and `Operator`; neither public signup nor business switching exists.

Only an active Administrator can call the membership RPCs: `create_business_member`, `update_business_member_role`, and `deactivate_business_member`. Memberships reference `auth.users`, so an Administrator cannot create an orphan identity. Row-level security limits reads to the caller's active business and self membership, while direct table writes are denied. Internal membership helpers bind their user argument to `auth.uid()` and execute only for `authenticated`, preventing foreign status disclosure. The database serializes Administrator demotion/deactivation with a business-row lock and rejects any mutation that would remove the final active Administrator.

Initial Administrator provisioning remains outside this migration because decision D08 is open. Test fixtures use the trusted database owner to provision synthetic businesses and identities only.

Rollback is forward-only: disable exposed RPC callers if necessary, then repair additively. Never delete stored memberships or their history.
