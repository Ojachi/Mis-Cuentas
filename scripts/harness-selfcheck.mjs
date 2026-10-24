import { spawnSync } from 'node:child_process';

const check = (command, expectedStatus, expectedOutput) => {
  const result = spawnSync(command[0], command.slice(1), { encoding: 'utf8' });
  const output = `${result.stdout}${result.stderr}`;
  if (result.status !== expectedStatus || !output.includes(expectedOutput)) {
    throw new Error(`Unexpected result for ${command.join(' ')}`);
  }
};

check(['node', 'scripts/check-plan.mjs'], 0, 'PASS plan:');
check(['node', 'scripts/check-release.mjs'], 1, 'BLOCKED: release evidence');
check(
  ['node', 'scripts/test-db.mjs', 'missing'],
  1,
  'Expected exactly one DB suite: harness',
);
console.log(
  'PASS harness self-check: plan, release block, and DB filter contracts.',
);
