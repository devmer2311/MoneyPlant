export type SemVer = { major: number; minor: number; patch: number };
export type ReleaseKind = 'major' | 'minor' | 'patch';

export function parseSemver(tagOrVersion: string): SemVer | null {
  const m = /^v?(\d+)\.(\d+)\.(\d+)/.exec(tagOrVersion.trim());
  if (!m) return null;
  return { major: Number(m[1]), minor: Number(m[2]), patch: Number(m[3]) };
}

/** Kind of a release relative to the previous (older) one. The first release counts as major. */
export function releaseKind(version: string, previous?: string): ReleaseKind {
  const cur = parseSemver(version);
  const prev = previous ? parseSemver(previous) : null;
  if (!cur || !prev) return 'major';
  if (cur.major !== prev.major) return 'major';
  if (cur.minor !== prev.minor) return 'minor';
  return 'patch';
}

export function compareSemver(a: string, b: string): number {
  const pa = parseSemver(a);
  const pb = parseSemver(b);
  if (!pa || !pb) return 0;
  return pa.major - pb.major || pa.minor - pb.minor || pa.patch - pb.patch;
}
