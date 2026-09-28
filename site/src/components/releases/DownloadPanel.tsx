import { latestRelease,formatSize,releaseDate,RELEASES_URL,type Release } from '../../lib/release-model';
import { useReleases } from './useReleases';
import ReleaseNotes from './ReleaseNotes';
export default function DownloadPanel({releases:initial,base='',expanded=false}: {releases:Release[];base?:string;expanded?:boolean}) {
  const {releases,status}=useReleases(initial);
  const latest=latestRelease(releases);
  const detail=latest && initial.some(r=>r.tag===latest.tag) ? `${base}/releases/${encodeURIComponent(latest.tag)}` : `${base}/releases#latest`;
  return <div className={`download-panel ${expanded?'panel':''}`}>
    {latest ? <>
      <p className="eyebrow">Latest stable release · <strong>v{latest.version}</strong></p>
      <p className="release-meta"><time dateTime={latest.publishedAt}>Released {releaseDate(latest.publishedAt)}</time>{latest.apk && <> · {formatSize(latest.apk.size)}</>}</p>
      <div className="action-row">
        {latest.apk ? <a className="button primary" href={latest.apk.url}>Download Android APK <span>v{latest.version} ↓</span></a> : <p>Android download is not available for this release yet.</p>}
        <a className="text-link" href={detail}>View release →</a>
      </div>
      {expanded && <><h2>{latest.name}</h2><p>{latest.summary}</p><ReleaseNotes sections={latest.sections}/>
        {latest.apk && <details className="verify"><summary>Verify this APK</summary><p>File: <code>{latest.apk.name}</code></p><p>SHA-256: <code>{latest.sha256 ?? 'Not supplied by GitHub. Check the release assets.'}</code></p><a href={latest.htmlUrl}>Original GitHub release</a></details>}
      </>}
    </> : <p>No releases found. Download information is temporarily unavailable.</p>}
    <p className="release-status" role="status">{status} <a href={RELEASES_URL}>Open GitHub Releases</a></p>
    <noscript>Live updates require JavaScript. Check GitHub Releases for the newest version.</noscript>
  </div>;
}
