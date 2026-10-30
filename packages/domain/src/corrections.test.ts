import { expect, test } from 'vitest';
import { correctionEffects } from './corrections';
import { addCop, operationEffects } from './money-effects';

test('correction reducer reverses exact effects before applying a replacement', () => {
  const original = operationEffects('purchase', '12000', 'cash');
  const replacement = operationEffects('purchase', '15000', 'cash');

  expect(correctionEffects(original, replacement)).toEqual({
    cash: -3000n,
    bank: 0n,
    profit: -3000n,
    flow: -3000n,
  });
  expect(
    addCop(original.profit, correctionEffects(original, replacement).profit),
  ).toBe(-15000n);
  expect(correctionEffects(original)).toEqual({
    cash: 12000n,
    bank: 0n,
    profit: 12000n,
    flow: 12000n,
  });
});
