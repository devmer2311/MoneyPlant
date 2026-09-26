// @ts-check
import { defineConfig } from 'astro/config';
import react from '@astrojs/react';
import sitemap from '@astrojs/sitemap';
import tailwindcss from '@tailwindcss/vite';

// Custom domain switch: set SITE_URL (and SITE_BASE for subpath hosting) and
// the build follows. Defaults target Cloudflare Pages at the domain root.
const site = process.env.SITE_URL ?? 'https://moneyplantbydev.pages.dev';
const base = process.env.SITE_BASE ?? '';

export default defineConfig({
  site,
  base,
  output: 'static',
  trailingSlash: 'ignore',
  integrations: [react(), sitemap()],
  vite: {
    plugins: [tailwindcss()],
  },
});
