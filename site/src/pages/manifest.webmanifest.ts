import type { APIRoute } from 'astro';

export const GET: APIRoute = () => {
  const base = import.meta.env.BASE_URL.replace(/\/$/, '');
  return new Response(
    JSON.stringify({
      name: 'Money Plant',
      short_name: 'Money Plant',
      description:
        'A private, offline-first expense tracker and bill splitter for Android.',
      start_url: `${base}/`,
      scope: `${base}/`,
      display: 'browser',
      background_color: '#111C17',
      theme_color: '#111C17',
      icons: [{ src: `${base}/favicon.svg`, sizes: 'any', type: 'image/svg+xml' }],
    }),
    { headers: { 'Content-Type': 'application/manifest+json' } },
  );
};
