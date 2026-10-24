import {
  copyFileSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  statSync,
  writeFileSync,
} from 'node:fs';
import { randomUUID } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

const suite = process.argv[2];
if (process.argv.length !== 3 || suite !== 'harness') {
  console.error('Expected exactly one DB suite: harness');
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
    command([
      ...scoped,
      'db',
      'query',
      '--local',
      '--file',
      join(root, 'tests', 'db', 'harness.sql'),
    ]);
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
