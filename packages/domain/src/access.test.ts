import { expect, test } from 'vitest';
import { businessRoles } from './access';

test('defines the only supported business roles', () => {
  expect(businessRoles).toEqual(['Administrator', 'Operator']);
});
