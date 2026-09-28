import { useState } from 'react';
import { type Release,latestRelease,releaseDate,formatSize,RELEASES_URL } from '../../lib/release-model';
import { useReleases } from './useReleases';
import ReleaseNotes from './ReleaseNotes';
export default function ReleasesExplorer({releases:initial,base=''}:{releases:Release[];base?:string}) {
  const {releases,status}=useReleases(initial);
  const [query,setQuery]=useState(''),[filter,setFilter]=useState('all'),[beta,setBeta]=useState(false);
  const latest=latestRelease(releases);
  const filtered=releases.filter(r=>(beta||!r.prerelease) && (filter==='all'||(filter==='fixes'?r.sections.fixes.length>0:r.sections.new.length>0)) && `${r.version} ${r.name} ${Object.values(r.sections).flat().join(' ')}`.toLowerCase().includes(query.toLowerCase().trim()));
  return <>
    <p role="status" className="release-status">{status} <a href={RELEASES_URL}>Open GitHub Releases</a></p>
    <div className="release-controls panel">
      <label>Find a release<input type="search" value={query} placeholder="Version or change…" onChange={e=>setQuery(e.target.value)}/></label>
      <label>Show<select value={filter} onChange={e=>setFilter(e.target.value)}><option value="all">All changes</option><option value="new">New features</option><option value="fixes">Bug fixes</option></select></label>
      <label className="check-label"><input type="checkbox" checked={beta} onChange={e=>setBeta(e.target.checked)}/>Include prereleases</label>
    </div>
    <p className="release-status" aria-live="polite">{filtered.length} {filtered.length===1?'release':'releases'} shown</p>
    {!filtered.length && <div className="panel"><h2>No releases found</h2><p>Try another version or clear the filters.</p><button className="button secondary" onClick={()=>{setQuery('');setFilter('all');setBeta(false);}}>Reset filters</button></div>}
    <div className="release-vine">{filtered.map(r=><article key={r.tag} id={r.tag===latest?.tag?'latest':r.tag} className={`panel release-card ${r.tag===latest?.tag?'is-latest':''}`}>
      <div className="action-row"><h2>v{r.version}</h2>{r.tag===latest?.tag && <span className="badge">Latest stable</span>}{r.prerelease && <span className="badge">Prerelease</span>}<span className="release-status">{r.kind} release</span></div>
      <p className="release-meta"><time dateTime={r.publishedAt}>{releaseDate(r.publishedAt)}</time>{r.apk && <> · {formatSize(r.apk.size)}</>}</p>
      <p className="release-title">{r.name}</p><p>{r.summary}</p><ReleaseNotes sections={r.sections}/>
      <div className="action-row">{r.apk ? <a className="button primary" href={r.apk.url}>Download Android APK <span>v{r.version} ↓</span></a> : <p>Android APK is not available for this release.</p>}
        {initial.some(b=>b.tag===r.tag) && <a className="text-link" href={`${base}/releases/${encodeURIComponent(r.tag)}`}>Release details →</a>}
        <a className="text-link" href={r.htmlUrl}>GitHub release ↗</a>
      </div>
      {r.apk && <details className="verify"><summary>File & checksum</summary><p><code>{r.apk.name}</code></p><p>SHA-256: <code>{r.sha256 ?? 'Not supplied by GitHub.'}</code></p></details>}
    </article>)}</div>
  </>;
}
