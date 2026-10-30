import { expect, test } from 'vitest';
import fixture from '../../../tests/fixtures/posting-hash.json';
import { canonicalPosting } from './posting';

test('posting canonical payload rejects numeric JSON money and is stable', () => {
  const payload = {
    version: '1',
    kind: 'sale',
    account: 'cash',
    amount: '24000',
    lines: [
      { name: 'Hot dog', quantity: '2', unitPrice: '12000', total: '24000' },
    ],
  };
  const canonical = canonicalPosting(payload);
  expect(canonical).toBe(
    '{"account": "cash", "amount": "24000", "kind": "sale", "lines": [{"name": "Hot dog", "quantity": "2", "total": "24000", "unitPrice": "12000"}], "version": "1"}',
  );
  expect(canonical.length).toBeGreaterThan(0);
  expect(() => canonicalPosting({ ...payload, amount: 24000 })).toThrow();
  expect(() => canonicalPosting({ ...payload, extra: true })).toThrow();
});

test('posting hash matches the PostgreSQL fixture with reordered keys and escaped Unicode', () => {
  const reversed = Object.fromEntries(
    Object.entries(fixture.payload).reverse(),
  );
  for (const payload of [fixture.payload, reversed]) {
    const canonical = canonicalPosting(payload);
    expect(canonical).toBe(fixture.canonical);
  }
});
