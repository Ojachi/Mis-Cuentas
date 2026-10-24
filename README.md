# Micu — finance for Perros al paso

Spanish-first finance PWA for one family business. The approved scope includes
sales, supplier purchases, operating expenses, owner movements, cash/bank
transfers, reconciliation and guarded Excel exchange. **This first scaffold does
not save records, authenticate users or work offline yet.**

## Local development

Use Node 24.15+ within the 24.x line, or Node 26+. Node 25 is not supported by the
test toolchain. The repository pins pnpm 12.14.0; a global pnpm installation is
not required:

```sh
npm exec --yes --package=pnpm@12.14.0 -- pnpm install --frozen-lockfile
npm run dev
```

Open the local URL printed by Vite. No Supabase credentials are needed for the
scaffold. Never put a service-role key in the browser or commit `.env` files.

## Checks

```sh
npm run lint
npm run format:check
npm run typecheck
npm test -- harness
npm run build
npm run check:plan
npm run test:db -- harness
npm run test:e2e -- harness
```

The matching root contracts also work through the pinned package manager:

```sh
npm exec --yes --package=pnpm@12.14.0 -- pnpm test -- <suite>
npm exec --yes --package=pnpm@12.14.0 -- pnpm test:db -- <suite>
npm exec --yes --package=pnpm@12.14.0 -- pnpm test:e2e -- <suite>
npm exec --yes --package=pnpm@12.14.0 -- pnpm check:plan
npm exec --yes --package=pnpm@12.14.0 -- pnpm check:release
```

`npm test -- <filter>` and the DB/browser runners select named fixtures. No
matching tests or unknown suites fail rather than silently passing. Each DB
harness run creates a fresh `/tmp/opencode/micu-t12-db-*` workdir, UUID-named
Supabase project, and local port. Every Supabase command uses that explicit
workdir; the repository config is never read and the runner never resets a DB.
Only a successfully started run cleans its own project with `--no-backup`; a
startup failure leaves an unowned target untouched. It is harness evidence only:
it does not prove application auth, RLS, tenant isolation, financial behavior,
offline storage, or a release.

Install the Chromium test browser once before local browser checks:

```sh
npm exec --yes --package=pnpm@12.14.0 -- pnpm exec playwright install chromium
```

`npm run check:release` intentionally fails until financial, manual pilot, and
isolated backup-recovery evidence exists. Use `npm run format` before final
checking; it only formats explicit application/tooling paths, not installed skills
or OpenSpec artifacts.

## Resume implementation

Start with [the implementation logbook](odd/tasks/finance-mvp.md), then the
[development tasks](openspec/changes/hot-dog-finance-mvp/tasks.md) and
[design/decision register](openspec/changes/hot-dog-finance-mvp/design.md).
Follow dependencies; never infer unresolved product rules from test fixtures.
Database/browser/CI/recovery gates are subsequent work, not implied by a successful
frontend build. No cloud deployment is configured or authorized by these commands.
