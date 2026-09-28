export type SemVer = { major: number; minor: number; patch: number; pre?: string };
export type ReleaseKind = 'major' | 'minor' | 'patch';
export function parseSemver(input: string): SemVer | null {
  const m = /^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$/.exec(input.trim());
  if (!m || m.slice(1, 4).some(n => !Number.isSafeInteger(Number(n))) || m[4]?.split('.').some(s => /^0\d+$/.test(s))) return null;
  return { major: +m[1]!, minor: +m[2]!, patch: +m[3]!, ...(m[4] ? { pre: m[4] } : {}) };
}
export function releaseKind(version: string, previous?: string): ReleaseKind {
  const a = parseSemver(version), b = previous ? parseSemver(previous) : null;
  return !a || !b || a.major !== b.major ? 'major' : a.minor !== b.minor ? 'minor' : 'patch';
}
export function compareSemver(a: string, b: string): number {
  const x = parseSemver(a), y = parseSemver(b);
  if (!x || !y) return 0;
  const core = x.major-y.major || x.minor-y.minor || x.patch-y.patch;
  if (core) return core;
  if (!x.pre || !y.pre) return x.pre ? -1 : y.pre ? 1 : 0;
  const p = x.pre.split('.'), q = y.pre.split('.');
  for (let i=0; i<Math.max(p.length,q.length); i++) {
    const u=p[i], v=q[i];
    if (u===v) continue;
    if (u===undefined) return -1;
    if (v===undefined) return 1;
    const un=/^\d+$/.test(u), vn=/^\d+$/.test(v);
    if (un && vn) return +u - +v;
    if (un !== vn) return un ? -1 : 1;
    return u<v ? -1 : 1;
  }
  return 0;
}
