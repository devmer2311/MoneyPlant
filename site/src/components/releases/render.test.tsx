import {expect,it} from 'vitest';
import {renderToStaticMarkup} from 'react-dom/server';
import DownloadPanel from './DownloadPanel';
import ReleasesExplorer from './ReleasesExplorer';
import {normalizeReleases} from '../../lib/release-model';
import raw from '../../data/releases.raw.json';
it('renders matching version, link, date and checksum from one record',()=>{
 const r=normalizeReleases(raw);const html=renderToStaticMarkup(<DownloadPanel releases={r} expanded/>);
 expect(html).toContain('v2.0.1');expect(html).toContain('money-plant-v2.0.1%2B4.apk');
 expect(html).toContain('26 September 2026');expect(html).toContain(r[0]!.sha256);
 expect(html).not.toContain('latest/download');
});
it('has useful no-release and no-asset states',()=>{
 const html=renderToStaticMarkup(<DownloadPanel releases={[]}/>);
 expect(html).toContain('No releases found');expect(html).toContain('Open GitHub Releases');
 const r=normalizeReleases(raw);r[0]!.apk=undefined;
 const missing=renderToStaticMarkup(<DownloadPanel releases={r}/>);
 expect(missing).toContain('not available for this release');
 expect(missing).not.toContain('Download Android APK');
});
it('shows human categories, highlights latest, keeps older versions',()=>{
 const html=renderToStaticMarkup(<ReleasesExplorer releases={normalizeReleases(raw)}/>);
 expect(html).toContain('Latest stable');expect(html).toContain('v1.0.1');
 expect(html).toContain('Export your ledger');expect(html).not.toContain('Full Changelog');
});
