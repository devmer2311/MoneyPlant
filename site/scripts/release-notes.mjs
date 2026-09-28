// The same hand-authored JSON feeds the website and GitHub release body.
import {readFileSync,writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
const [tag,output]=process.argv.slice(2);
if (!/^v\d+\.\d+\.\d+(?:-beta\.[1-9]\d*)?$/.test(tag??'') || !output) throw new Error('Usage: node site/scripts/release-notes.mjs vX.Y.Z[-beta.BUILD] output.md');
const data=JSON.parse(readFileSync(fileURLToPath(new URL('../src/data/changelog.json',import.meta.url)),'utf8'));
const release=data[tag];
const labels={new:'What’s new',fixes:'Bug fixes',design:'Improvements',privacy:'Privacy',backup:'Backup',sync:'Sync',other:'Other changes'};
if (!release || typeof release.title!=='string' || !release.title.trim()) throw new Error(`Write human release notes for ${tag} in site/src/data/changelog.json before publishing.`);
let count=0;
const lines=['<!-- money-plant-notes:v1 -->','',release.title,''];
for (const [key,label] of Object.entries(labels)) {
 const items=release[key];
 if (!Array.isArray(items) || items.some(s=>typeof s!=='string'||!s.trim()||/[\r\n]/.test(s))) throw new Error(`Invalid ${key} notes`);
 if(items.length){count+=items.length;lines.push('## '+label,...items.map(s=>'- '+s),'');}
}
if (!count) throw new Error('Release notes must describe at least one real change.');
writeFileSync(output,lines.join('\n'),'utf8');
