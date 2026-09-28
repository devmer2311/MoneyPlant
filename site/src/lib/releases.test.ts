import {afterEach,expect,it,vi} from 'vitest';
import {normalizeReleases,latestRelease,fetchReleases,REPO} from './release-model';
const gh=(tag='v1.0.0',extra={})=>({tag_name:tag,published_at:'2026-01-01T00:00:00Z',draft:false,prerelease:false,assets:[],...extra});
const asset=(tag='v1.0.0',name='money-plant-v1.0.0+1.apk')=>({name,browser_download_url:`https://github.com/${REPO}/releases/download/${tag}/${encodeURIComponent(name)}`,size:123,download_count:2,digest:'sha256:'+'a'.repeat(64)});
afterEach(()=>{vi.unstubAllGlobals();delete process.env.REQUIRE_FRESH_RELEASES;});
it('sorts semantically, excludes drafts and prereleases from latest',()=>{
 const r=normalizeReleases([gh('v1.9.0',{published_at:'2026-09-01'}),gh('v1.10.0'),gh('v3.0.0-rc.1'),gh('v4.0.0',{prerelease:true}),gh('v5.0.0',{draft:true})]);
 expect(latestRelease(r)?.tag).toBe('v1.10.0');
 expect(r).toHaveLength(4);
});
it('selects one tag-matching universal asset and its own digest',()=>{
 const r=normalizeReleases([gh('v1.0.0',{assets:[asset('v1.0.0','money-plant.apk'),asset('v1.0.0','money-plant-v0.9.0+1.apk'),asset()]})])[0]!;
 expect(r.apk?.name).toBe('money-plant-v1.0.0+1.apk');
 expect(r.sha256).toBe('a'.repeat(64));
});
it.each([
 [asset('v0.9.0')],
 [{...asset(),browser_download_url:'https://evil.test/app.apk'}],
 [asset('v1.0.0','money-plant-v1.0.0-arm64.apk')],
 [asset(),asset('v1.0.0','money-plant-v1.0.0+2.apk')],
 [{...asset(),size:0}],
])('rejects mismatched, unsafe, architecture-specific or ambiguous assets',(...assets)=>{
 expect(normalizeReleases([gh('v1.0.0',{assets})])[0]?.apk).toBeUndefined();
});
it('never silently offers an older APK as the newest version',()=>{
 const r=normalizeReleases([gh('v1.1.0'),gh('v1.0.0',{assets:[asset()]})]);
 expect(latestRelease(r)?.version).toBe('1.1.0');
 expect(latestRelease(r)?.apk).toBeUndefined();
});
it('treats malformed metadata as unavailable and empty lists as empty',()=>{
 expect(()=>normalizeReleases({message:'rate limit'})).toThrow();
 expect(()=>normalizeReleases([gh('v1.0.0junk')])).toThrow();
 expect(()=>normalizeReleases([gh('v1.0.0',{published_at:'bad'})])).toThrow();
 expect(normalizeReleases([])).toEqual([]);
});
it('paginates, validates status and requests revalidation',async()=>{
 const first=Array.from({length:100},(_,i)=>gh(`v1.0.${i}`));
 const mock=vi.fn().mockResolvedValueOnce({ok:true,json:async()=>first}).mockResolvedValueOnce({ok:true,json:async()=>[gh('v2.0.0')]});
 vi.stubGlobal('fetch',mock);
 expect(await fetchReleases()).toHaveLength(101);
 expect(mock.mock.calls[0]?.[1].cache).toBe('no-cache');
 expect(mock.mock.calls[1]?.[0]).toContain('page=2');
});
it.each([403,404,429,500])('fails cleanly on HTTP %s',async status=>{
 vi.stubGlobal('fetch',vi.fn(async()=>({ok:false,status})));
 await expect(fetchReleases()).rejects.toThrow();
});
it('uses the validated snapshot offline and fails production builds when freshness is required',async()=>{
 vi.stubGlobal('fetch',vi.fn(async()=>{throw new Error('offline');}));
 vi.resetModules();
 expect((await (await import('./releases')).getReleases()).length).toBeGreaterThan(0);
 vi.resetModules();process.env.REQUIRE_FRESH_RELEASES='1';
 await expect((await import('./releases')).getReleases()).rejects.toThrow('offline');
});
