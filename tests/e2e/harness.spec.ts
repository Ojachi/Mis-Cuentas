import { expect, test } from '@playwright/test';

test('shows the Spanish scaffold and its current limitation', async ({
  page,
}) => {
  await page.goto('/');

  await expect(page.locator('html')).toHaveAttribute('lang', 'es-CO');
  await expect(
    page.getByRole('heading', { name: 'Registro del negocio' }),
  ).toBeVisible();
  await expect(
    page.getByText(
      'Esta versión todavía no guarda movimientos ni funciona sin conexión.',
    ),
  ).toBeVisible();
});
