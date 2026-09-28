// Server only. Builds never rewrite tracked source files.
import snapshot from '../data/releases.raw.json';
import { fetchReleases, normalizeReleases, type Release } from './release-model';
export * from './release-model';
let cache: Promise<Release[]> | undefined;
export function getReleases(): Promise<Release[]> {
  return cache ??= fetchReleases(process.env.GITHUB_TOKEN).catch(error => {
    if (process.env.REQUIRE_FRESH_RELEASES === '1') throw error;
    console.warn('[releases] GitHub unavailable; using checked-in snapshot.');
    try { return normalizeReleases(snapshot); } catch { return []; }
  });
}
export { releaseDate as relativeTime } from './release-model';
