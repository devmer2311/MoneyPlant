// Freshness check: once per session, asks GitHub for the latest release. If it
// is newer than the version baked in at build, swaps every [data-latest-version]
// text and [data-latest-apk] link, and shows a small toast.
import { compareSemver } from './semver.ts';

const KEY = 'mp-latest';

type Latest = { version: string; apkUrl: string | null };

async function fetchLatest(): Promise<Latest | null> {
  try {
    const cached = sessionStorage.getItem(KEY);
    if (cached) return JSON.parse(cached) as Latest;
  } catch {
    /* storage blocked */
  }
  try {
    const res = await fetch('https://api.github.com/repos/devmer2311/MoneyPlant/releases/latest', {
      headers: { Accept: 'application/vnd.github+json' },
    });
    if (!res.ok) return null;
    const data = (await res.json()) as {
      tag_name: string;
      assets: { name: string; browser_download_url: string }[];
    };
    const apk = data.assets.find((a) => /^money-plant-v.+\.apk$/.test(a.name));
    const latest: Latest = {
      version: data.tag_name.replace(/^v/, ''),
      apkUrl: apk?.browser_download_url ?? null,
    };
    try {
      sessionStorage.setItem(KEY, JSON.stringify(latest));
    } catch {
      /* storage blocked */
    }
    return latest;
  } catch {
    return null;
  }
}

export async function initLatestCheck(builtVersion: string) {
  const latest = await fetchLatest();
  if (!latest || compareSemver(latest.version, builtVersion) <= 0) return;
  for (const el of document.querySelectorAll('[data-latest-version]')) {
    el.textContent = `v${latest.version}`;
  }
  if (latest.apkUrl) {
    for (const el of document.querySelectorAll<HTMLAnchorElement>('[data-latest-apk]')) {
      el.href = latest.apkUrl;
    }
  }
  const toast = document.createElement('div');
  toast.setAttribute('role', 'status');
  toast.className = 'fixed bottom-5 left-1/2 z-50 -translate-x-1/2 rounded-full px-5 py-2.5 text-sm font-bold shadow-lg';
  toast.style.background = 'var(--brand)';
  toast.style.color = 'var(--on-brand)';
  toast.textContent = `v${latest.version} just landed 🌱`;
  document.body.appendChild(toast);
  setTimeout(() => toast.remove(), 6000);
}
