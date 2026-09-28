import { fetchReleases, type Release } from './release-model';
export const RELEASE_TTL = 60_000;
// Shared in-memory cache. Reload always revalidates; no indefinite session cache.
// Failed requests are also deduplicated for one minute to avoid retry storms.
export function createReleaseClient(loader: () => Promise<Release[]> = fetchReleases, now = Date.now) {
  let pending: Promise<Release[]> | undefined;
  let checkedAt = -Infinity;
  return () => {
    if (!pending || now()-checkedAt >= RELEASE_TTL) { checkedAt=now(); pending=loader(); }
    return pending;
  };
}
export const checkReleases = createReleaseClient();
