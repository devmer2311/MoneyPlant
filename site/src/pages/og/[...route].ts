// Build-time OG images: one per top-level page and one per release.
import { OGImageRoute } from 'astro-og-canvas';
import { getReleases, relativeTime } from '../../lib/releases.ts';

const releases = await getReleases();

const pages: Record<string, { title: string; description: string }> = {
  home: { title: 'Money Plant', description: 'Grow your money. Private, offline, Android.' },
  releases: { title: 'The growth vine', description: 'Every Money Plant release, newest at the top.' },
  install: { title: 'Plant it in 3 steps', description: 'The friendly APK install guide.' },
  roadmap: { title: 'Growing next', description: 'What is being built, queued, and dreamed about.' },
};
for (const r of releases) {
  pages[`releases-${r.tag.replaceAll('.', '-')}`] = {
    title: `Money Plant v${r.version}`,
    description: `Released ${relativeTime(r.publishedAt)}. Download the APK and read the changelog.`,
  };
}

const route = await OGImageRoute({
  pages,
  getImageOptions: (_path, page: (typeof pages)[string]) => ({
    title: page.title,
    description: page.description,
    logo: { path: './public/favicon-og.png', size: [96] },
    bgGradient: [
      [17, 28, 23],
      [23, 61, 49],
    ],
    font: {
      title: { size: 72, weight: 'Bold', color: [241, 243, 236], families: ['Outfit'] },
      description: { size: 32, color: [186, 200, 190], families: ['Manrope'] },
    },
    fonts: ['./src/assets/fonts/Outfit-Bold.woff2', './src/assets/fonts/Manrope-Regular.woff2'],
    padding: 80,
  }),
});

export const getStaticPaths = route.getStaticPaths;
export const GET = route.GET;
