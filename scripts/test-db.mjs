import {
  copyFileSync,
  cpSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  statSync,
  writeFileSync,
} from 'node:fs';
import { randomUUID } from 'node:crypto';
import { spawn, spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

const suite = process.argv[2];
if (
  process.argv.length !== 3 ||
  !['harness', 'access', 'money', 'posting', 'corrections'].includes(suite)
) {
  console.error(
    'Expected exactly one DB suite: harness, access, money, posting or corrections',
  );
  process.exitCode = 1;
} else {
  const root = resolve(import.meta.dirname, '..');
  const scratchParent = join(tmpdir(), 'opencode');
  const projectId = `micu-t12-${randomUUID().slice(0, 16)}`;
  const port = 49152 + (Number.parseInt(randomUUID().slice(0, 4), 16) % 16384);
  const config = `project_id = "${projectId}"

[db]
port = ${port}
shadow_port = ${port - 1}
major_version = 17

[db.seed]
enabled = true
sql_paths = ["./seed.sql"]
`;

  const command = (args) => {
    const result = spawnSync('supabase', args, { stdio: 'inherit' });
    if (result.error) throw result.error;
    if (result.status !== 0) {
      const action = args.find((argument) =>
        ['start', 'stop', 'query'].includes(argument),
      );
      const error = new Error(
        `supabase ${action} failed with exit ${result.status ?? 1}`,
      );
      error.exitCode = result.status ?? 1;
      throw error;
    }
  };

  let primaryError;
  let startAttempted = false;
  let workdir;

  try {
    if (!statSync(scratchParent).isDirectory()) {
      throw new Error(`Scratch parent is not a directory: ${scratchParent}`);
    }
    workdir = mkdtempSync(join(scratchParent, 'micu-t12-db-'));
    const supabaseDir = join(workdir, 'supabase');
    const configPath = join(supabaseDir, 'config.toml');
    const seedPath = join(supabaseDir, 'seed.sql');

    mkdirSync(supabaseDir);
    writeFileSync(configPath, config);
    copyFileSync(join(root, 'supabase', 'seed.sql'), seedPath);
    cpSync(
      join(root, 'supabase', 'migrations'),
      join(supabaseDir, 'migrations'),
      { recursive: true },
    );
    if (readFileSync(configPath, 'utf8') !== config) {
      throw new Error(`Unexpected generated Supabase config: ${configPath}`);
    }

    const scoped = ['--workdir', workdir];
    startAttempted = true;
    command([
      ...scoped,
      'start',
      '-x',
      'gotrue,realtime,storage-api,imgproxy,kong,mailpit,postgrest,postgres-meta,studio,edge-runtime,logflare,vector,supavisor',
    ]);
    const query = (file) =>
      command([
        ...scoped,
        'db',
        'query',
        '--local',
        '--file',
        join(root, 'tests', 'db', file),
      ]);

    const concurrentQuery = (file) =>
      new Promise((resolveQuery, rejectQuery) => {
        const child = spawn(
          'supabase',
          [
            ...scoped,
            'db',
            'query',
            '--local',
            '--file',
            join(root, 'tests', 'db', file),
          ],
          { stdio: 'inherit' },
        );
        child.on('error', rejectQuery);
        child.on('close', (status) => {
          if (status === 0) resolveQuery();
          else
            rejectQuery(
              new Error(`concurrent ${file} failed with exit ${status ?? 1}`),
            );
        });
      });

    if (suite === 'harness') {
      query('harness.sql');
    } else if (suite === 'money') {
      const fixtures = readFileSync(
        join(root, 'tests', 'fixtures', 'money-effects.json'),
        'utf8',
      );
      const probePath = join(workdir, 'money.sql');
      writeFileSync(
        probePath,
        readFileSync(
          join(root, 'tests', 'db', 'money', 'check.sql'),
          'utf8',
        ).replace(
          '__MONEY_FIXTURES__',
          `'${fixtures.replaceAll("'", "''")}'::jsonb`,
        ),
      );
      command([...scoped, 'db', 'query', '--local', '--file', probePath]);
    } else if (suite === 'posting') {
      query('posting/check.sql');
      query('posting/security.sql');
      query('posting/rollback.sql');
      const fixture = readFileSync(
        join(root, 'tests', 'fixtures', 'posting-hash.json'),
        'utf8',
      );
      const probePath = join(workdir, 'posting-parity.sql');
      writeFileSync(
        probePath,
        readFileSync(
          join(root, 'tests', 'db', 'posting', 'parity.sql'),
          'utf8',
        ).replace(
          '__POSTING_FIXTURE__',
          `'${fixture.replaceAll("'", "''")}'::jsonb`,
        ),
      );
      command([...scoped, 'db', 'query', '--local', '--file', probePath]);
      const concurrent = await Promise.allSettled([
        concurrentQuery('posting/concurrent-a.sql'),
        concurrentQuery('posting/concurrent-b.sql'),
      ]);
      if (concurrent.some((result) => result.status === 'rejected'))
        throw new Error('concurrent posting probe failed');
      query('posting/assert.sql');
    } else if (suite === 'corrections') {
      query('corrections/check.sql');
      query('corrections/security.sql');
      query('corrections/rollback.sql');
      const concurrent = await Promise.allSettled([
        concurrentQuery('corrections/concurrent-a.sql'),
        concurrentQuery('corrections/concurrent-b.sql'),
      ]);
      if (concurrent.some((result) => result.status === 'rejected'))
        throw new Error('concurrent correction probe failed');
      query('corrections/assert.sql');
      query('corrections/independent-probes.sql');
    } else {
      query('access/setup.sql');
      query('access/bypass-probe.sql');
      query('access/anon-probe.sql');

      for (const [kind, first, second] of [
        ['deactivation', 'concurrent-a.sql', 'concurrent-b.sql'],
        ['demotion', 'demote-a.sql', 'demote-b.sql'],
      ]) {
        const concurrent = await Promise.allSettled([
          concurrentQuery(`access/${first}`),
          concurrentQuery(`access/${second}`),
        ]);
        if (
          concurrent.filter((result) => result.status === 'rejected').length !==
          1
        ) {
          throw new Error(
            `expected exactly one concurrent last-Admin ${kind} to fail`,
          );
        }
      }
      query('access/assert.sql');
    }
  } catch (error) {
    primaryError = error;
  }

  if (startAttempted) {
    try {
      command(['--workdir', workdir, 'stop', '--no-backup']);
    } catch (cleanupError) {
      if (primaryError) {
        console.error(
          `Cleanup failed after primary failure: ${cleanupError.message}`,
        );
      } else {
        primaryError = cleanupError;
      }
    }
  }

  if (primaryError) {
    console.error(primaryError.message);
    process.exitCode = primaryError.exitCode ?? 1;
  }
}
