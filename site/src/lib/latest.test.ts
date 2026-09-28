import {expect,it,vi} from 'vitest';
import {createReleaseClient,RELEASE_TTL} from './latest';
it('deduplicates concurrent islands and expires within one minute',async()=>{
 let time=0;const loader=vi.fn(async()=>[]);const get=createReleaseClient(loader,()=>time);
 await Promise.all([get(),get(),get()]);expect(loader).toHaveBeenCalledTimes(1);
 time=RELEASE_TTL-1;await get();expect(loader).toHaveBeenCalledTimes(1);
 time=RELEASE_TTL;await get();expect(loader).toHaveBeenCalledTimes(2);
});
it('caches errors briefly and recovers on the next check',async()=>{
 let time=0;const loader=vi.fn().mockRejectedValueOnce(new Error('offline')).mockResolvedValue([]);
 const get=createReleaseClient(loader,()=>time);
 await expect(get()).rejects.toThrow();await expect(get()).rejects.toThrow();
 expect(loader).toHaveBeenCalledTimes(1);
 time=RELEASE_TTL;expect(await get()).toEqual([]);
});
