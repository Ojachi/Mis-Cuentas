import { expect, test } from 'vitest';
import { currency } from './index';

test('exports the domain package through the workspace contract', () => {
  expect(currency).toBe('COP');
});
