import react from '@vitejs/plugin-react';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    include: [
      'apps/web/src/**/*.test.tsx',
      'packages/**/*.test.ts',
      'tests/**/*.test.ts',
    ],
    setupFiles: ['tests/setup.ts'],
  },
});
