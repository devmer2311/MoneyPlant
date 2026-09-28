// Plain text only: release HTML is never injected into the page.
export const categories = { new: 'What’s new', fixes: 'Bug fixes', design: 'Improvements', privacy: 'Privacy', backup: 'Backup', sync: 'Sync', other: 'Other changes' } as const;
export type Sections = Record<keyof typeof categories, string[]>;
export const emptySections = (): Sections => ({ new: [], fixes: [], design: [], privacy: [], backup: [], sync: [], other: [] });
/** Only explicitly authored notes in our release-body format become user copy. */
export function parseSections(body: string): Sections {
  const sections = emptySections();
  if (!body.includes('<!-- money-plant-notes:v1 -->')) return sections;
  let key: keyof Sections | undefined;
  for (const line of body.split(/\r?\n/)) {
    if (line.startsWith('## ')) key = Object.entries(categories).find(([,label]) => line.slice(3).trim() === label)?.[0] as keyof Sections | undefined;
    else if (key && /^- \S/.test(line)) sections[key].push(line.slice(2).trim());
  }
  return sections;
}
export function noteSummary(sections: Sections): string {
  if (sections.fixes.length && Object.entries(sections).every(([key,items]) => key === 'fixes' || !items.length)) return 'A little tending. This release focuses on bug fixes. 🌱';
  return Object.values(sections).some(items => items.length) ? 'Here’s what changed in this release.' : 'Detailed release notes are not available yet.';
}
