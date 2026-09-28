import { useEffect, useState } from 'react';
import { checkReleases, RELEASE_TTL } from '../../lib/latest';
import type { Release } from '../../lib/release-model';
export function useReleases(initial: Release[]) {
  const [releases,setReleases]=useState(initial);
  const [status,setStatus]=useState('Checking latest version…');
  useEffect(() => {
    let active=true;
    const update=() => {
      if (document.hidden) return;
      void checkReleases().then(data => {
        if (!active) return;
        setReleases(data);
        setStatus(`Checked GitHub at ${new Date().toLocaleTimeString([],{hour:'2-digit',minute:'2-digit'})}.`);
      },() => { if (active) setStatus('GitHub is unavailable. Showing the last available release information; it may be out of date.'); });
    };
    update();
    const timer=setInterval(update,RELEASE_TTL);
    document.addEventListener('visibilitychange',update);
    return () => {active=false;clearInterval(timer);document.removeEventListener('visibilitychange',update);};
  },[]);
  return {releases,status};
}
