// Explicit maintenance command. Normal builds never change this snapshot.
import { writeFileSync } from 'node:fs';
const rows=[];
for(let page=1;page<=50;page++){
 const response=await fetch(`https://api.github.com/repos/devmer2311/MoneyPlant/releases?per_page=100&page=${page}`,{
  signal:AbortSignal.timeout(10000),cache:'no-cache',
  headers:{Accept:'application/vnd.github+json',...(process.env.GITHUB_TOKEN?{Authorization:`Bearer ${process.env.GITHUB_TOKEN}`}:{})}
 });
 if(!response.ok) throw new Error(`GitHub returned ${response.status}; snapshot was not changed.`);
 const batch=await response.json();
 if(!Array.isArray(batch)) throw new Error('Invalid API response');
 for(const r of batch) {
  if(r.draft)continue;
  if(typeof r.tag_name!=='string'||!Array.isArray(r.assets)||!Number.isFinite(Date.parse(r.published_at)))throw new Error('Malformed metadata');
  rows.push({tag_name:r.tag_name,published_at:r.published_at,draft:r.draft,prerelease:r.prerelease,body:r.body,
   assets:r.assets.map(a=>({name:a.name,browser_download_url:a.browser_download_url,size:a.size,download_count:a.download_count,digest:a.digest}))});
 }
 if(batch.length<100){
  writeFileSync(new URL('../src/data/releases.raw.json',import.meta.url),JSON.stringify(rows,null,2)+'\n');
  console.log(`Saved ${rows.length} public releases. Run npm test and review the diff before committing.`);
  break;
 }
 if(page===50)throw new Error('Pagination exceeded; snapshot was not changed.');
}
