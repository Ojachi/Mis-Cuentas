import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { expect, test } from 'vitest';
import { canonicalPosting } from '../../packages/domain/src/posting';

test('posting UTF-8 SHA256 matches the shared PostgreSQL receipt fixture', () => {
  const fixture = JSON.parse(
    readFileSync('tests/fixtures/posting-hash.json', 'utf8'),
  ) as { payload: unknown; hash: string };
  expect(
    createHash('sha256')
      .update(canonicalPosting(fixture.payload), 'utf8')
      .digest('hex'),
  ).toBe(fixture.hash);
});
