import { expect,it } from 'vitest';
import { emptySections,noteSummary,parseSections } from './notes';
import { renderToStaticMarkup } from 'react-dom/server';
import ReleaseNotes from '../components/releases/ReleaseNotes';
it('ignores generated PR and commit history',()=>{
 expect(Object.values(parseSections('## What’s new\n- fix bug\nFull Changelog: x')).flat()).toEqual([]);
});
it('reads only populated authored categories',()=>{
 const s=parseSections('<!-- money-plant-notes:v1 -->\n## Bug fixes\n- Fixed duplicate payments.\n## Unknown\n- Raw commit.');
 expect(s.fixes).toEqual(['Fixed duplicate payments.']);
 expect(s.new).toEqual([]);
 expect(Object.values(s).flat()).toHaveLength(1);
 expect(noteSummary(s)).toContain('focuses on bug fixes');
});
it('does not infer features from a version number or missing notes',()=>{
 expect(noteSummary(emptySections())).toContain('not available');
 const s=emptySections();s.new=['Export a PDF'];
 expect(noteSummary(s)).not.toContain('bug fixes');
});
it('escapes untrusted notes rather than injecting HTML',()=>{
 const s=emptySections();s.new=['<img src=x onerror=alert(1)>'];
 const html=renderToStaticMarkup(ReleaseNotes({sections:s}));
 expect(html).toContain('&lt;img');
 expect(html).not.toContain('<img');
 expect(html).not.toContain('Bug fixes');
});
