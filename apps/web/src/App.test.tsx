import { render, screen } from '@testing-library/react';
import { expect, test } from 'vitest';
import { App } from './App';

test('shows a Spanish scaffold without claiming financial persistence', () => {
  render(<App />);

  expect(
    screen.getByRole('heading', { name: 'Registro del negocio', level: 1 }),
  ).toBeInTheDocument();
  expect(screen.getByText('Moneda del negocio: COP')).toBeInTheDocument();
  expect(
    screen.getByText(
      'Esta versión todavía no guarda movimientos ni funciona sin conexión.',
    ),
  ).toBeInTheDocument();
});
