import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

// https://astro.build/config
export default defineConfig({
  site: 'https://patrickpinace.github.io',
  base: '/m-finance/',  // ← TU USTAW NA SZTYWNO ŚCIEŻKĘ REPO
  vite: {
    plugins: [tailwindcss()]
  }
});
