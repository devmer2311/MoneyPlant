import type { APIRoute } from 'astro';
import { getReleases } from '../lib/releases.ts';

const escapeXml = (s: string) =>
  s.replace(/[<>&'"]/g, (c) => ({ '<': '&lt;', '>': '&gt;', '&': '&amp;', "'": '&apos;', '"': '&quot;' })[c]!);

export const GET: APIRoute = async ({ site }) => {
  const base = import.meta.env.BASE_URL.replace(/\/$/, '');
  const releases = await getReleases();
  const link = (path: string) => new URL(`${base}${path}`, site).toString();

  const items = releases
    .filter((r) => !r.prerelease)
    .map(
      (r) => `    <item>
      <title>Money Plant v${escapeXml(r.version)}</title>
      <link>${link(`/releases/${r.tag}`)}</link>
      <guid>${link(`/releases/${r.tag}`)}</guid>
      <pubDate>${new Date(r.publishedAt).toUTCString()}</pubDate>
      <description>${escapeXml(r.bodyHtml)}</description>
    </item>`,
    )
    .join('\n');

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Money Plant releases</title>
    <link>${link('/releases')}</link>
    <description>New versions of the Money Plant Android app</description>
${items}
  </channel>
</rss>`;
  return new Response(xml, { headers: { 'Content-Type': 'application/rss+xml; charset=utf-8' } });
};
