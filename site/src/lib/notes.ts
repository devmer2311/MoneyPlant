// Sanitising and section-parsing for GitHub's rendered release notes (body_html).
// ponytail: regex-based sanitiser; it only ever runs at build time on our own
// repo's release notes (defence in depth). Swap for `sanitize-html` if notes
// ever come from an untrusted source.

const ALLOWED_TAGS = new Set([
  'a', 'p', 'ul', 'ol', 'li', 'strong', 'em', 'b', 'i', 'code', 'pre',
  'h1', 'h2', 'h3', 'h4', 'blockquote', 'br', 'hr', 'img', 'del', 'table',
  'thead', 'tbody', 'tr', 'th', 'td', 'details', 'summary', 'span',
]);
const ALLOWED_ATTRS: Record<string, Set<string>> = {
  a: new Set(['href', 'title', 'rel']),
  img: new Set(['src', 'alt', 'width', 'height', 'loading']),
  td: new Set(['align']),
  th: new Set(['align']),
};

export function sanitizeHtml(html: string): string {
  return html.replace(/<\/?([a-zA-Z][a-zA-Z0-9-]*)((?:\s[^<>]*?)?)(\/?)>/g, (_, tag: string, attrs: string, selfClose: string) => {
    const name = tag.toLowerCase();
    if (!ALLOWED_TAGS.has(name)) return '';
    if (!attrs) return `<${_.startsWith('</') ? '/' : ''}${name}${selfClose}>`;
    const allowed = ALLOWED_ATTRS[name] ?? new Set<string>();
    const kept: string[] = [];
    for (const m of attrs.matchAll(/([a-zA-Z-]+)\s*=\s*("[^"]*"|'[^']*'|[^\s"'>]+)/g)) {
      const attr = m[1]!.toLowerCase();
      const value = m[2]!.replace(/^["']|["']$/g, '');
      if (!allowed.has(attr)) continue;
      if ((attr === 'href' || attr === 'src') && /^\s*(javascript|data|vbscript):/i.test(value)) continue;
      kept.push(`${attr}="${value.replace(/"/g, '&quot;')}"`);
    }
    if (name === 'a') kept.push('rel="noopener"');
    return `<${name}${kept.length ? ' ' + kept.join(' ') : ''}${selfClose}>`;
  });
}

export type Sections = { new: string[]; fixes: string[]; design: string[]; other: string[] };

const stripTags = (s: string) =>
  s
    .replace(/<[^>]+>/g, '')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, ' ')
    .trim();

/** Groups release-note bullets under the ✨ New / 🐛 Fixes / 🎨 Design headings
 *  written by .github/release.yml; anything else lands in `other`. */
export function parseSections(bodyHtml: string): Sections {
  const sections: Sections = { new: [], fixes: [], design: [], other: [] };
  const parts = bodyHtml.split(/<h[23][^>]*>/i);
  for (const [i, part] of parts.entries()) {
    const headingEnd = part.search(/<\/h[23]>/i);
    const heading = i === 0 ? '' : stripTags(part.slice(0, Math.max(headingEnd, 0))).toLowerCase();
    const body = i === 0 ? part : part.slice(headingEnd);
    const bucket = heading.includes('new')
      ? sections.new
      : heading.includes('fix')
        ? sections.fixes
        : heading.includes('design')
          ? sections.design
          : sections.other;
    for (const li of body.matchAll(/<li[^>]*>([\s\S]*?)<\/li>/gi)) {
      const text = stripTags(li[1]!);
      if (text) bucket.push(text);
    }
  }
  return sections;
}
