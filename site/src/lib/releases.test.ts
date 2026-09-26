import { afterEach, describe, expect, it, vi } from 'vitest';
import { getReleases, normalizeReleases } from './releases.ts';

const gh = (over: Record<string, unknown>) => ({
  tag_name: 'v1.0.0',
  name: null,
  published_at: '2026-01-01T00:00:00Z',
  prerelease: false,
  draft: false,
  body_html: '',
  html_url: 'https://github.com/devmer2311/MoneyPlant/releases/tag/v1.0.0',
  assets: [],
  ...over,
});

afterEach(() => vi.unstubAllGlobals());

describe('normalizeReleases', () => {
  it('excludes drafts, finds the versioned APK, and derives kind', async () => {
    const releases = await normalizeReleases(
      [
        gh({
          tag_name: 'v1.1.0',
          published_at: '2026-02-01T00:00:00Z',
          assets: [
            { name: 'money-plant.apk', browser_download_url: 'u0', size: 1, download_count: 5 },
            { name: 'money-plant-v1.1.0+3.apk', browser_download_url: 'u1', size: 9, download_count: 7 },
            { name: 'money-plant-v1.1.0+3.apk.sha256', browser_download_url: 'u2', size: 1, download_count: 0 },
          ],
        }),
        gh({ tag_name: 'v1.0.1-draft', draft: true }),
        gh({ tag_name: 'v1.0.0' }),
      ] as never[],
      false,
    );
    expect(releases.map((r) => r.tag)).toEqual(['v1.1.0', 'v1.0.0']);
    expect(releases[0]!.apk?.name).toBe('money-plant-v1.1.0+3.apk');
    expect(releases[0]!.apk?.downloads).toBe(7);
    expect(releases[0]!.kind).toBe('minor');
    expect(releases[1]!.kind).toBe('major');
  });
});

describe('getReleases', () => {
  it('merges paginated pages and falls back to the snapshot on failure', async () => {
    // Page 1 has 100 releases, page 2 has 1 → 101 merged.
    const page1 = Array.from({ length: 100 }, (_, i) =>
      gh({ tag_name: `v1.0.${200 - i}`, published_at: `2026-01-01T00:${String(i).padStart(2, '0')}:00Z` }),
    );
    const page2 = [gh({ tag_name: 'v0.1.0' })];
    vi.stubGlobal(
      'fetch',
      vi.fn(async (url: string) => ({
        ok: true,
        json: async () => (new URL(String(url)).searchParams.get('page') === '1' ? page1 : page2),
      })),
    );
    const releases = await getReleases();
    expect(releases).toHaveLength(101);

    // Cached module promise means the fallback needs a fresh module registry.
    vi.resetModules();
    vi.stubGlobal('fetch', vi.fn(async () => { throw new Error('offline'); }));
    const fresh = await import('./releases.ts');
    const fallback = await fresh.getReleases();
    expect(fallback.length).toBeGreaterThan(0);
    expect(fallback[0]).toHaveProperty('tag');
  });
});
