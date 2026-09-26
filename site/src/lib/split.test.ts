// Mirrors the app's own cases in test/garden_store_test.dart so both
// implementations stay paise-identical.
import { describe, expect, it } from 'vitest';
import { allocateSplit, parseMoney } from './split.ts';

describe('parseMoney', () => {
  it('parses rupees to paise', () => {
    expect(parseMoney('1,234.56')).toBe(123456);
    expect(parseMoney('0.01')).toBe(1);
    for (const bad of ['-1', '0', '1.234', 'NaN', '1e5', '']) {
      expect(() => parseMoney(bad)).toThrow();
    }
  });
});

describe('allocateSplit', () => {
  it('equal split distributes every paise deterministically', () => {
    expect(allocateSplit(10000, 'equal', [1, 1, 1])).toEqual([3334, 3333, 3333]);
    expect(allocateSplit(1, 'equal', [1, 1, 1])).toEqual([1, 0, 0]);
  });

  it('custom, percentage and shares allocate exact totals', () => {
    expect(allocateSplit(10000, 'custom', [4000, 6000])).toEqual([4000, 6000]);
    expect(allocateSplit(10000, 'percentage', [2550, 7450])).toEqual([2550, 7450]);
    expect(allocateSplit(10000, 'shares', [2, 1, 1])).toEqual([5000, 2500, 2500]);
    for (let total = 1; total < 300; total++) {
      const parts = allocateSplit(total, 'shares', [1, 2, 5, 9]);
      expect(parts.reduce((a, b) => a + b, 0)).toBe(total);
    }
  });

  it('rejects invalid totals and participants', () => {
    expect(() => allocateSplit(100, 'custom', [20, 30])).toThrow();
    expect(() => allocateSplit(100, 'percentage', [4000, 5000])).toThrow();
    expect(() => allocateSplit(100, 'shares', [0, 0])).toThrow();
    expect(() => allocateSplit(100, 'shares', [-1, 2])).toThrow();
    expect(() => allocateSplit(100, 'equal', [1])).toThrow();
  });
});
