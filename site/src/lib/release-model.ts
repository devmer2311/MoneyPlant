import curated from '../data/changelog.json';
import { emptySections, noteSummary, parseSections, type Sections } from './notes';
import { compareSemver, parseSemver, releaseKind, type ReleaseKind } from './semver';
export const REPO = 'devmer2311/MoneyPlant';
export const RELEASES_URL = `https://github.com/${REPO}/releases`;
export type Release = {
  tag: string; version: string; name: string; publishedAt: string; prerelease: boolean;
  htmlUrl: string; kind: ReleaseKind; sections: Sections; summary: string;
  apk?: { name: string; url: string; size: number; downloads: number }; sha256?: string;
};
type Asset = { name: string; browser_download_url: string; size: number; download_count?: number; digest?: string };
type RawRelease = { tag_name: string; published_at: string; draft: boolean; prerelease: boolean; body?: string; assets: Asset[] };
const object = (v: unknown): v is Record<string, unknown> => !!v && typeof v === 'object';
function validRaw(v: unknown): v is RawRelease {
  return object(v) && typeof v.tag_name === 'string' && !!parseSemver(v.tag_name) &&
    typeof v.published_at === 'string' && Number.isFinite(Date.parse(v.published_at)) &&
    typeof v.draft === 'boolean' && typeof v.prerelease === 'boolean' && Array.isArray(v.assets);
}
function matchingAsset(a: unknown, tag: string): a is Asset {
  if (!object(a) || typeof a.name !== 'string' || typeof a.browser_download_url !== 'string' || typeof a.size !== 'number' || !Number.isFinite(a.size) || a.size <= 0) return false;
  const version = tag.replace(/^v/, '');
  const match = /^money-plant-v(.+)\.apk$/.exec(a.name);
  if (!match || !parseSemver(match[1]!) || match[1]!.split('+')[0] !== version.split('+')[0]) return false;
  if (version.includes('+') && match[1] !== version) return false;
  try {
    const url = new URL(a.browser_download_url);
    return url.origin === 'https://github.com' && !url.search && !url.hash &&
      decodeURIComponent(url.pathname) === `/${REPO}/releases/download/${tag}/${a.name}`;
  } catch { return false; }
}
export function normalizeReleases(raw: unknown): Release[] {
  if (!Array.isArray(raw)) throw new Error('Invalid release response');
  if (raw.some(r => !object(r) || (r.draft !== true && !validRaw(r)))) throw new Error('Malformed release metadata');
  const published = raw.filter(validRaw).filter(r => !r.draft)
    .sort((a,b) => compareSemver(b.tag_name,a.tag_name) || a.tag_name.localeCompare(b.tag_name));
  return published.map((r,i) => {
    const candidates = r.assets.filter(a => matchingAsset(a,r.tag_name));
    // Multiple universal artifacts are ambiguous; never guess a build.
    const asset = candidates.length === 1 ? candidates[0] : undefined;
    const authored = (curated as Record<string, Sections & { title: string }>)[r.tag_name];
    const sections = authored ?? parseSections(typeof r.body === 'string' ? r.body : '');
    const clean = Object.fromEntries(Object.keys(emptySections()).map(k => [k,sections[k as keyof Sections]])) as Sections;
    const older = published.slice(i+1).find(x => !x.prerelease && !parseSemver(x.tag_name)?.pre);
    const digest = typeof asset?.digest === 'string' ? asset.digest.match(/^sha256:([a-f0-9]{64})$/i)?.[1]?.toLowerCase() : undefined;
    return {
      tag:r.tag_name, version:r.tag_name.replace(/^v/,''), name:authored?.title ?? `Money Plant ${r.tag_name}`,
      publishedAt:r.published_at, prerelease:r.prerelease || !!parseSemver(r.tag_name)?.pre,
      htmlUrl:`${RELEASES_URL}/tag/${encodeURIComponent(r.tag_name)}`,
      kind:releaseKind(r.tag_name,older?.tag_name), sections:clean, summary:noteSummary(clean),
      apk:asset ? {name:asset.name,url:asset.browser_download_url,size:asset.size,downloads:asset.download_count ?? 0} : undefined,
      sha256:digest,
    };
  });
}
export const stableReleases = (releases: Release[]) => releases.filter(r => !r.prerelease).sort((a,b) => compareSemver(b.version,a.version));
export const latestRelease = (releases: Release[]) => stableReleases(releases)[0];
export const formatSize = (bytes: number) => `${(bytes/1024/1024).toFixed(1)} MB`;
export const releaseDate = (iso: string) => new Date(iso).toLocaleDateString('en-GB',{day:'numeric',month:'long',year:'numeric',timeZone:'UTC'});
export async function fetchReleases(token?: string): Promise<Release[]> {
  const all: unknown[] = [];
  const signal = AbortSignal.timeout(10000);
  for (let page=1;page<=50;page++) {
    const res = await fetch(`https://api.github.com/repos/${REPO}/releases?per_page=100&page=${page}`,{
      signal,cache:'no-cache',headers:{Accept:'application/vnd.github+json',...(token ? {Authorization:`Bearer ${token}`} : {})},
    });
    if (!res.ok) throw new Error(`GitHub API ${res.status}`);
    const batch: unknown = await res.json();
    if (!Array.isArray(batch)) throw new Error('Invalid release list');
    all.push(...batch);
    if (batch.length<100) return normalizeReleases(all);
  }
  throw new Error('Release pagination limit exceeded');
}
