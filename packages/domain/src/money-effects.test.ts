import { expect, test } from 'vitest';
import fixtures from '../../../tests/fixtures/money-effects.json';
import {
  addCop,
  invertCop,
  lineTotal,
  operationEffects,
  openingBalances,
  parseCop,
  balanceAfter,
} from './money-effects';

test('money-effects rejects malformed whole COP and accepts exact signed-64 boundaries', () => {
  for (const value of fixtures.invalidCop)
    expect(() => parseCop(value)).toThrow();
  for (const value of fixtures.validCop)
    expect(parseCop(value).toString()).toBe(value);
  for (const value of [null, undefined, 1, {}, true])
    expect(() => parseCop(value)).toThrow();
  for (const value of ['0', '-1'])
    expect(() => parseCop(value, true)).toThrow();
  expect(() => addCop(9223372036854775807n, 1n)).toThrow();
  expect(() => invertCop(-9223372036854775808n)).toThrow();
});

test('money-effects shares exact unit and three-decimal purchase line fixtures with PostgreSQL', () => {
  for (const line of fixtures.lines) {
    const total = () => lineTotal(line.quantity, line.price, line.measure);
    if (line.total === null) expect(total).toThrow();
    else expect(total().toString()).toBe(line.total);
  }
});

test('money-effects preserves all seven account effects and separates profit from funds', () => {
  let profit = 0n;
  let flow = 0n;
  for (const operation of fixtures.operations) {
    const effect = operationEffects(
      operation.kind,
      operation.amount,
      operation.account,
    );
    for (const field of ['cash', 'bank', 'profit', 'flow'] as const)
      expect(effect[field].toString()).toBe(operation[field]);
    profit = addCop(profit, effect.profit);
    flow = addCop(flow, effect.flow);
  }
  expect(profit).toBe(21000n);
  expect(flow).toBe(27000n);
  expect(() => operationEffects('unknown', '100', 'cash')).toThrow();
  expect(() => operationEffects('sale', '100', 'unknown')).toThrow();
  expect(() => operationEffects('sale', '-1', 'cash')).toThrow();
});

test('money-effects validates manual/imported dated baselines without treating them as profit', () => {
  for (const source of ['manual', 'import']) {
    const baseline = openingBalances('10000', '-2000', '2026-10-24', source);
    expect(baseline.cash).toBe(10000n);
    expect(baseline.bank).toBe(-2000n);
    expect(baseline.source).toBe(source);
    expect(balanceAfter(baseline.cash, [-12000n])).toEqual({
      amount: -2000n,
      negative: true,
    });
  }
  expect(balanceAfter(0n, [1n])).toEqual({ amount: 1n, negative: false });
  expect(() => openingBalances('0', '0', '2026-02-30', 'manual')).toThrow();
  expect(() => openingBalances('0', '0', '2026-10-24', 'unknown')).toThrow();
  expect(() =>
    openingBalances(undefined, '0', '2026-10-24', 'manual'),
  ).toThrow();
});
