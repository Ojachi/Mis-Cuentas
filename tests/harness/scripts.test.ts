import {
  chmodSync,
  cpSync,
  existsSync,
  mkdtempSync,
  mkdirSync,
  readFileSync,
  writeFileSync,
} from 'node:fs';
import { createHash } from 'node:crypto';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { expect, test } from 'vitest';

const run = (script: string, ...arguments_: string[]) =>
  spawnSync(process.execPath, [script, ...arguments_], {
    cwd: process.cwd(),
    encoding: 'utf8',
  });

test('plan gate validates the current task graph', () => {
  const result = run('scripts/check-plan.mjs');

  expect(result.status).toBe(0);
  expect(result.stdout).toContain('PASS plan:');
  expect(result.stdout).toContain('24 tasks, 9 decisions');
});

test('release gate fails while required evidence is absent', () => {
  const result = run('scripts/check-release.mjs');

  expect(result.status).toBe(1);
  expect(result.stderr).toContain('BLOCKED: release evidence is missing');
});

test('DB runner rejects a suite before it can touch local infrastructure', () => {
  const result = run('scripts/test-db.mjs', 'not-a-suite');

  expect(result.status).toBe(1);
  expect(result.stderr).toContain('Expected exactly one DB suite: harness');
});

const scratchParent = '/tmp/opencode';
const scratch = mkdtempSync(join(scratchParent, 'micu-t12-regression-'));
const fakeBin = join(scratch, 'bin');
const fakeLog = join(scratch, 'supabase.log');
mkdirSync(fakeBin);
writeFileSync(
  join(fakeBin, 'supabase'),
  `#!/usr/bin/env node
import { appendFileSync, unlinkSync } from 'node:fs';
const args = process.argv.slice(2);
appendFileSync(process.env.SUPABASE_FAKE_LOG, JSON.stringify(args) + '\\n');
const command = args.find((argument) => ['start', 'stop', 'query'].includes(argument));
if (command === 'start' && process.env.SUPABASE_FAKE_OWNED_RESOURCE) appendFileSync(process.env.SUPABASE_FAKE_OWNED_RESOURCE, 'owned');
if (command === 'stop' && process.env.SUPABASE_FAKE_OWNED_RESOURCE) unlinkSync(process.env.SUPABASE_FAKE_OWNED_RESOURCE);
if (command === process.env.SUPABASE_FAKE_FAIL) process.exit(Number(process.env.SUPABASE_FAKE_EXIT));
if (args.at(-1)?.includes('/access/') && args.at(-1)?.endsWith('-b.sql')) process.exit(44);
`,
);
chmodSync(join(fakeBin, 'supabase'), 0o755);

const runDb = (...arguments_: string[]) => {
  writeFileSync(fakeLog, '');
  return spawnSync(process.execPath, ['scripts/test-db.mjs', ...arguments_], {
    cwd: process.cwd(),
    encoding: 'utf8',
    env: {
      ...process.env,
      PATH: `${fakeBin}:${process.env.PATH}`,
      SUPABASE_FAKE_LOG: fakeLog,
    },
  });
};
const calls = () =>
  readFileSync(fakeLog, 'utf8')
    .trim()
    .split('\n')
    .filter(Boolean)
    .map((line) => JSON.parse(line) as string[]);

test('DB runner rejects extra arguments before invoking infrastructure', () => {
  const result = runDb('harness', 'extra');

  expect(result.status).toBe(1);
  expect(calls()).toEqual([]);
});

test('DB runner accepts the explicit access suite', () => {
  const result = runDb('access');

  expect(result.status).toBe(0);
});

test('DB runner accepts the explicit money suite with shared boundary fixtures', () => {
  const result = runDb('money');
  expect(result.status).toBe(0);
  expect(calls().some((call) => call.includes('query'))).toBe(true);
});

test('DB runner accepts the explicit posting suite', () => {
  const result = runDb('posting');
  expect(result.status).toBe(0);
});

test('DB runner cleans an owned partial start while preserving its failure', () => {
  const result = runDb('harness');

  expect(result.status).toBe(0);
  const successfulCalls = calls();
  const workdir = successfulCalls[0]?.[1];
  expect(workdir).toContain('/tmp/opencode/micu-t12-db-');
  expect(
    successfulCalls.every(
      (call) => call[0] === '--workdir' && call[1] === workdir,
    ),
  ).toBe(true);
  expect(successfulCalls.flat()).not.toContain('reset');
  const config = readFileSync(join(workdir, 'supabase/config.toml'), 'utf8');
  const projectId = config.match(/^project_id = "(.+)"$/m)?.[1];
  expect(projectId).toMatch(/^micu-t12-[0-9a-f-]{16}$/);

  const ownedResource = join(scratch, 'owned-partial-start');
  const foreignData = join(scratch, 'foreign-data');
  writeFileSync(fakeLog, '');
  writeFileSync(foreignData, 'foreign data');
  const foreignHash = createHash('sha256')
    .update(readFileSync(foreignData))
    .digest('hex');
  const failedStart = spawnSync(
    process.execPath,
    ['scripts/test-db.mjs', 'harness'],
    {
      cwd: process.cwd(),
      encoding: 'utf8',
      env: {
        ...process.env,
        PATH: `${fakeBin}:${process.env.PATH}`,
        SUPABASE_FAKE_LOG: fakeLog,
        SUPABASE_FAKE_OWNED_RESOURCE: ownedResource,
        SUPABASE_FAKE_FAIL: 'start',
        SUPABASE_FAKE_EXIT: '41',
      },
    },
  );

  expect(failedStart.status).toBe(41);
  const failedCalls = calls();
  expect(failedCalls.some((call) => call.includes('stop'))).toBe(true);
  expect(failedCalls[0]?.[1]).toBe(failedCalls.at(-1)?.[1]);
  expect(existsSync(ownedResource)).toBe(false);
  expect(
    createHash('sha256').update(readFileSync(foreignData)).digest('hex'),
  ).toBe(foreignHash);
});

test('DB runner preserves a query failure after owned cleanup', () => {
  const result = spawnSync(
    process.execPath,
    ['scripts/test-db.mjs', 'harness'],
    {
      cwd: process.cwd(),
      encoding: 'utf8',
      env: {
        ...process.env,
        PATH: `${fakeBin}:${process.env.PATH}`,
        SUPABASE_FAKE_LOG: fakeLog,
        SUPABASE_FAKE_FAIL: 'query',
        SUPABASE_FAKE_EXIT: '43',
      },
    },
  );

  expect(result.status).toBe(43);
  expect(calls().some((call) => call.includes('stop'))).toBe(true);
});

test('DB runner reports a failed owned cleanup', () => {
  const result = spawnSync(
    process.execPath,
    ['scripts/test-db.mjs', 'harness'],
    {
      cwd: process.cwd(),
      encoding: 'utf8',
      env: {
        ...process.env,
        PATH: `${fakeBin}:${process.env.PATH}`,
        SUPABASE_FAKE_LOG: fakeLog,
        SUPABASE_FAKE_FAIL: 'stop',
        SUPABASE_FAKE_EXIT: '52',
      },
    },
  );

  expect(result.status).toBe(52);
  expect(result.stderr).toContain('supabase stop failed with exit 52');
});

const planFixture = () => {
  const fixture = mkdtempSync(join(scratchParent, 'micu-t12-plan-'));
  cpSync(resolve('openspec'), join(fixture, 'openspec'), { recursive: true });
  cpSync(resolve('odd'), join(fixture, 'odd'), { recursive: true });
  mkdirSync(join(fixture, 'scripts'));
  cpSync('scripts/check-plan.mjs', join(fixture, 'scripts/check-plan.mjs'));
  return fixture;
};

test('plan gate accepts recorded approvals without completing dependent tasks', () => {
  const fixture = planFixture();
  const designPath = join(
    fixture,
    'openspec/changes/hot-dog-finance-mvp/design.md',
  );
  const source = readFileSync(designPath, 'utf8');
  writeFileSync(designPath, source.replaceAll('| OPEN |', '| APPROVED |'));
  const result = spawnSync(process.execPath, ['scripts/check-plan.mjs'], {
    cwd: fixture,
    encoding: 'utf8',
  });
  expect(result.status).toBe(0);
  expect(result.stdout).toContain('24 tasks, 9 decisions');
});

test('plan gate rejects broken local links and anchors while ignoring fenced history', () => {
  const fixture = planFixture();
  const tasksPath = join(
    fixture,
    'openspec/changes/hot-dog-finance-mvp/tasks.md',
  );
  const original = readFileSync(tasksPath, 'utf8');

  writeFileSync(tasksPath, `${original}\n[broken](missing.md)\n`);
  let result = spawnSync(process.execPath, ['scripts/check-plan.mjs'], {
    cwd: fixture,
    encoding: 'utf8',
  });
  expect(result.status).toBe(1);
  expect(result.stderr).toContain('missing link target');

  writeFileSync(tasksPath, `${original}\n[broken](design.md#missing-anchor)\n`);
  result = spawnSync(process.execPath, ['scripts/check-plan.mjs'], {
    cwd: fixture,
    encoding: 'utf8',
  });
  expect(result.status).toBe(1);
  expect(result.stderr).toContain('missing anchor');

  writeFileSync(
    tasksPath,
    `${original}\n[external](https://example.invalid)\n\`\`\`text\n[ignored](missing.md)\n\`\`\`\n`,
  );
  result = spawnSync(process.execPath, ['scripts/check-plan.mjs'], {
    cwd: fixture,
    encoding: 'utf8',
  });
  expect(result.status).toBe(0);
});
