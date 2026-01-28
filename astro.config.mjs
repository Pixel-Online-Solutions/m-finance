import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import react from '@astrojs/react';

// https://astro.build/config
export default defineConfig({
  // Site i base są automatycznie ustawiane przez GitHub Actions workflow
  // podczas buildu na GitHub Pages. Dla lokalnego developmentu (pnpm dev)
  // nie są potrzebne. Można je opcjonalnie dodać jeśli chcesz testować
  // produkcyjny build lokalnie (pnpm build && pnpm preview)
  site: 'https://patrickpinace.github.io',
  base: '/m-finance/',
  integrations: [react()],
  vite: {
    plugins: [tailwindcss()],
    resolve: {
      alias: {
        '@styles': '/src/styles',
        '@components': '/src/components',
        '@layouts': '/src/layouts',
        '@utils': '/src/utils',
      },
    },
  },
});
