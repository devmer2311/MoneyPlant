import { describe, expect, it } from 'vitest';
import { compareSemver, parseSemver, releaseKind } from './semver.ts';

describe('parseSemver', () => {
  it('parses tags with and without v', () => {
    expect(parseSemver('v1.2.3')).toEqual({ major: 1, minor: 2, patch: 3 });
    expect(parseSemver('10.0.1')).toEqual({ major: 10, minor: 0, patch: 1 });
    expect(parseSemver('nightly')).toBeNull();
  });
  it('rejects partial versions, leading zeroes and invalid prereleases', () => {
    for (const tag of ['1.2.3junk', '01.2.3', '1.2', '1.2.3-01', '1.2.3+']) expect(parseSemver(tag)).toBeNull();
    expect(parseSemver('v2.0.1+4')).toEqual({ major: 2, minor: 0, patch: 1 });
  });
});

describe('releaseKind', () => {
  it('is major for the first release', () => {
    expect(releaseKind('1.0.1')).toBe('major');
  });
  it('diffs against the previous release', () => {
    expect(releaseKind('2.0.0', '1.9.3')).toBe('major');
    expect(releaseKind('1.5.0', '1.4.9')).toBe('minor');
    expect(releaseKind('1.4.2', '1.4.1')).toBe('patch');
  });
});

describe('compareSemver', () => {
  it('orders versions', () => {
    expect(compareSemver('1.10.0', '1.9.9')).toBeGreaterThan(0);
    expect(compareSemver('1.0.0', '1.0.0')).toBe(0);
    expect(compareSemver('0.9.0', '1.0.0')).toBeLessThan(0);
  });
  it('orders prereleases correctly and ignores build metadata', () => {
    expect(compareSemver('1.0.0', '1.0.0-rc.1')).toBeGreaterThan(0);
    expect(compareSemver('1.0.0-rc.10', '1.0.0-rc.2')).toBeGreaterThan(0);
    expect(compareSemver('1.0.0+9', '1.0.0+2')).toBe(0);
  });
});
