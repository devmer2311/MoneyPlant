import { describe, expect, it } from 'vitest';
import { parseSections, sanitizeHtml } from './notes.ts';

const SAMPLE = `
<h2>What's Changed</h2>
<h3>✨ New</h3>
<ul>
<li>Add UPI QR codes to statements by <a href="https://github.com/devmer2311">@devmer2311</a></li>
<li>Recurring expense reminders</li>
</ul>
<h3>🐛 Fixes</h3>
<ul><li>Fix rounding in split totals</li></ul>
<h3>🎨 Design</h3>
<ul><li>New Mango Sunset theme</li></ul>
<h3>Other</h3>
<ul><li>chore: bump dependencies</li></ul>
<p><strong>Full Changelog</strong>: <a href="https://github.com/devmer2311/MoneyPlant/compare/v1.0.0...v1.1.0">link</a></p>
`;

describe('parseSections', () => {
  it('groups bullets under the release.yml headings', () => {
    const s = parseSections(SAMPLE);
    expect(s.new).toEqual([
      'Add UPI QR codes to statements by @devmer2311',
      'Recurring expense reminders',
    ]);
    expect(s.fixes).toEqual(['Fix rounding in split totals']);
    expect(s.design).toEqual(['New Mango Sunset theme']);
    expect(s.other).toEqual(['chore: bump dependencies']);
  });

  it('puts headingless bullets in other', () => {
    const s = parseSections('<ul><li>lonely bullet</li></ul>');
    expect(s.other).toEqual(['lonely bullet']);
    expect(s.new).toEqual([]);
  });
});

describe('sanitizeHtml', () => {
  it('drops disallowed tags and event handlers', () => {
    const out = sanitizeHtml(
      '<p onclick="evil()">hi</p><script>evil()</script><a href="javascript:evil()">x</a><a href="https://ok.dev" title="t">y</a>',
    );
    expect(out).not.toContain('script');
    expect(out).not.toContain('onclick');
    expect(out).not.toContain('javascript:');
    expect(out).toContain('<p>hi</p>');
    expect(out).toContain('href="https://ok.dev"');
    expect(out).toContain('rel="noopener"');
  });
});
