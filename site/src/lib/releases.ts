// Build-time release data: fetches every GitHub release (paginated), normalises
// it, and falls back to the committed snapshot when the API is unreachable.
import { writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import releaseSnapshot from '../data/releases.snapshot.json';
import { parseSections, sanitizeHtml, type Sections } from './notes.ts';
import { releaseKind, type ReleaseKind } from './semver.ts';

export const REPO = 'devmer2311/MoneyPlant';
export const STABLE_APK_URL = `https://github.com/${REPO}/releases/latest/download/money-plant.apk`;

export type Release = {
  tag: string;
  version: string;
  name: string;
  publishedAt: string;
  prerelease: boolean;
  bodyHtml: string;
  htmlUrl: string;
  apk?: { name: string; url: string; size: number; downloads: number };
  sha256?: string;
  kind: ReleaseKind;
  sections: Sections;
};

const SNAPSHOT = resolve(process.cwd(), 'src/data/releases.snapshot.json');
const APK_RE = /^money-plant-v.+\.apk$/;

type GhAsset = { name: string; browser_download_url: string; size: number; download_count: number };
type GhRelease = {
  tag_name: string;
  name: string | null;
  published_at: string;
  prerelease: boolean;
  draft: boolean;
  body_html?: string;
  html_url: string;
  assets: GhAsset[];
};

function headers(): HeadersInit {
  const h: Record<string, string> = {
    Accept: 'application/vnd.github.html+json',
    'X-GitHub-Api-Version': '2022-11-28',
  };
  const token = process.env.GITHUB_TOKEN;
  if (token) h.Authorization = `Bearer ${token}`;
  return h;
}

async function fetchAllPages(): Promise<GhRelease[]> {
  const all: GhRelease[] = [];
  for (let page = 1; page < 50; page++) {
    const res = await fetch(
      `https://api.github.com/repos/${REPO}/releases?per_page=100&page=${page}`,
      { headers: headers(), signal: AbortSignal.timeout(10000) },
    );
    if (!res.ok) throw new Error(`GitHub API ${res.status}`);
    const batch = (await res.json()) as GhRelease[];
    all.push(...batch);
    if (batch.length < 100) break;
  }
  return all;
}

async function fetchSha256(asset: GhAsset | undefined): Promise<string | undefined> {
  if (!asset) return undefined;
  try {
    const res = await fetch(asset.browser_download_url, { signal: AbortSignal.timeout(10000) });
    if (!res.ok) return undefined;
    const text = await res.text();
    return /^[0-9a-f]{64}/i.exec(text.trim())?.[0]?.toLowerCase();
  } catch {
    return undefined;
  }
}

export async function normalizeReleases(raw: GhRelease[], fetchChecksums = true): Promise<Release[]> {
  const published = raw
    .filter((r) => !r.draft)
    .sort((a, b) => (a.published_at < b.published_at ? 1 : -1));
  const releases: Release[] = [];
  for (const [i, r] of published.entries()) {
    const apk = r.assets.find((a) => APK_RE.test(a.name));
    const shaAsset = apk ? r.assets.find((a) => a.name === `${apk.name}.sha256`) : undefined;
    const version = r.tag_name.replace(/^v/, '');
    const older = published.slice(i + 1).find((p) => !p.prerelease);
    const bodyHtml = sanitizeHtml(r.body_html ?? '');
    releases.push({
      tag: r.tag_name,
      version,
      name: r.name ?? r.tag_name,
      publishedAt: r.published_at,
      prerelease: r.prerelease,
      bodyHtml,
      htmlUrl: r.html_url,
      apk: apk
        ? {
            name: apk.name,
            url: apk.browser_download_url,
            size: apk.size,
            downloads: apk.download_count,
          }
        : undefined,
      sha256: fetchChecksums ? await fetchSha256(shaAsset) : undefined,
      kind: releaseKind(version, older ? older.tag_name.replace(/^v/, '') : undefined),
      sections: parseSections(bodyHtml),
    });
  }
  return releases;
}

let cache: Promise<Release[]> | undefined;

/** All published releases, newest first. Never throws: the committed snapshot
 *  is the offline fallback, and every successful fetch refreshes it. */
export function getReleases(): Promise<Release[]> {
  cache ??= (async () => {
    try {
      const releases = await normalizeReleases(await fetchAllPages());
      try {
        if (!process.env.VITEST) writeFileSync(SNAPSHOT, JSON.stringify(releases, null, 2));
      } catch {
        /* read-only checkout: snapshot refresh is best-effort */
      }
      return releases;
    } catch (err) {
      console.warn(`[releases] GitHub API unavailable (${err}); using snapshot`);
      return releaseSnapshot as Release[];
    }
  })();
  return cache;
}

export const stableReleases = (releases: Release[]) => releases.filter((r) => !r.prerelease);
export const latestRelease = (releases: Release[]) => stableReleases(releases)[0];
export const totalDownloads = (releases: Release[]) =>
  releases.reduce((sum, r) => sum + (r.apk?.downloads ?? 0), 0);

export function formatSize(bytes: number): string {
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
}

export function relativeTime(iso: string, now = new Date()): string {
  const days = Math.floor((now.getTime() - new Date(iso).getTime()) / 86_400_000);
  if (days <= 0) return 'today';
  if (days === 1) return 'yesterday';
  if (days < 30) return `${days} days ago`;
  const months = Math.floor(days / 30);
  if (months < 12) return months === 1 ? 'a month ago' : `${months} months ago`;
  const years = Math.floor(days / 365);
  return years === 1 ? 'a year ago' : `${years} years ago`;
}
