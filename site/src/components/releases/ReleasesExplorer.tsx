// The Growth Vine: every release as a node on a self-drawing vine, with search,
// filter chips, beta toggle, sort, and "what's new since my version".
import { useEffect, useMemo, useRef, useState } from 'react';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { Flip } from 'gsap/Flip';
import { compareSemver } from '../../lib/semver.ts';

gsap.registerPlugin(ScrollTrigger, Flip);

export type VineRelease = {
  tag: string;
  version: string;
  publishedAt: string;
  relative: string;
  kind: 'major' | 'minor' | 'patch';
  prerelease: boolean;
  downloads: number;
  sizeLabel: string;
  apkUrl?: string;
  detailUrl: string;
  bullets: string[];
  sections: { new: string[]; fixes: string[]; design: string[]; other: string[] };
};

const KIND_ICON = { major: '🌸', minor: '🍃', patch: '🌿' } as const;
const FILTERS = ['All', 'Major', 'Minor', 'Patch', 'Has fixes', 'Has new features'] as const;
type Filter = (typeof FILTERS)[number];

function matches(r: VineRelease, filter: Filter, query: string): boolean {
  if (filter === 'Major' && r.kind !== 'major') return false;
  if (filter === 'Minor' && r.kind !== 'minor') return false;
  if (filter === 'Patch' && r.kind !== 'patch') return false;
  if (filter === 'Has fixes' && r.sections.fixes.length === 0) return false;
  if (filter === 'Has new features' && r.sections.new.length === 0) return false;
  if (query) {
    const haystack = `${r.version} ${r.bullets.join(' ')} ${Object.values(r.sections).flat().join(' ')}`.toLowerCase();
    // ponytail: substring match, not fuzzy scoring; enough until releases number in the hundreds.
    if (!query.toLowerCase().split(/\s+/).every((w) => haystack.includes(w))) return false;
  }
  return true;
}

function SectionChips({ r }: { r: VineRelease }) {
  const chips = [
    { label: `✨ ${r.sections.new.length} new`, show: r.sections.new.length > 0, bg: 'var(--receive)', fg: 'var(--on-receive)' },
    { label: `🐛 ${r.sections.fixes.length} fixes`, show: r.sections.fixes.length > 0, bg: 'var(--owe)', fg: 'var(--on-owe)' },
    { label: `🎨 design`, show: r.sections.design.length > 0, bg: 'var(--chart-5)', fg: 'var(--on-receive)' },
  ].filter((c) => c.show);
  if (!chips.length) return null;
  return (
    <p className="m-0 mt-2 flex flex-wrap gap-1.5">
      {chips.map((c) => (
        <span key={c.label} className="rounded-full px-2.5 py-0.5 text-xs font-bold" style={{ background: c.bg, color: c.fg }}>
          {c.label}
        </span>
      ))}
    </p>
  );
}

function ReleaseCard({ r, latest }: { r: VineRelease; latest: boolean }) {
  return (
    <article
      className="release-card relative rounded-[var(--radius)] border p-5"
      style={{
        background: 'var(--surface)',
        borderColor: 'color-mix(in srgb, var(--ink) 10%, transparent)',
        viewTransitionName: `release-${r.version.replaceAll('.', '-')}`,
      }}
      data-tag={r.tag}
    >
      <header className="flex flex-wrap items-baseline gap-x-3 gap-y-1">
        <h3 className="m-0 text-3xl" style={{ fontFamily: 'var(--font-display)' }}>
          v{r.version}
        </h3>
        {latest && (
          <span className="rounded-full px-2.5 py-0.5 text-xs font-bold" style={{ background: 'var(--brand)', color: 'var(--on-brand)', boxShadow: '0 0 14px var(--brand)' }}>
            LATEST
          </span>
        )}
        {r.prerelease && (
          <span className="rounded-full border px-2.5 py-0.5 text-xs font-bold" style={{ borderColor: 'var(--owe)' }}>
            beta
          </span>
        )}
        <span className="text-sm text-ink-muted" style={{ fontVariantNumeric: 'tabular-nums' }}>
          {new Date(r.publishedAt).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })} · {r.relative}
          {r.sizeLabel ? ` · ${r.sizeLabel}` : ''}
          {r.downloads > 0 ? ` · ${r.downloads.toLocaleString('en-IN')} downloads` : ''}
        </span>
      </header>
      <SectionChips r={r} />
      {r.bullets.length > 0 && (
        <ul className="mb-0 mt-3 list-disc space-y-1 pl-5 text-sm text-ink-muted">
          {r.bullets.slice(0, 3).map((b) => (
            <li key={b}>{b}</li>
          ))}
        </ul>
      )}
      <p className="m-0 mt-4 flex gap-3">
        {r.apkUrl && (
          <a href={r.apkUrl} className="rounded-full px-4 py-1.5 text-sm font-bold no-underline" style={{ background: 'var(--brand)', color: 'var(--on-brand)' }}>
            Download
          </a>
        )}
        <a href={r.detailUrl} className="rounded-full border px-4 py-1.5 text-sm font-bold no-underline" style={{ borderColor: 'color-mix(in srgb, var(--ink) 18%, transparent)', color: 'var(--ink)' }}>
          Details
        </a>
      </p>
    </article>
  );
}

export default function ReleasesExplorer({ releases }: { releases: VineRelease[] }) {
  const [filter, setFilter] = useState<Filter>('All');
  const [query, setQuery] = useState('');
  const [beta, setBeta] = useState(false);
  const [oldestFirst, setOldestFirst] = useState(false);
  const [mine, setMine] = useState('');
  const listRef = useRef<HTMLDivElement>(null);
  const vineRef = useRef<SVGPathElement>(null);

  const stable = useMemo(() => releases.filter((r) => !r.prerelease), [releases]);
  const latestTag = stable[0]?.tag;

  const visible = useMemo(() => {
    let list = releases.filter((r) => (beta || !r.prerelease) && matches(r, filter, query));
    if (mine) list = list.filter((r) => compareSemver(r.version, mine) > 0);
    if (oldestFirst) list = [...list].reverse();
    return list;
  }, [releases, filter, query, beta, oldestFirst, mine]);

  const combined = useMemo(() => {
    if (!mine) return null;
    const newer = releases.filter((r) => !r.prerelease && compareSemver(r.version, mine) > 0);
    if (!newer.length) return null;
    const merge = (key: 'new' | 'fixes' | 'design' | 'other') => newer.flatMap((r) => r.sections[key]);
    return { count: newer.length, latest: newer[0]!, new: merge('new'), fixes: merge('fixes'), design: merge('design'), other: merge('other') };
  }, [mine, releases]);

  // Animate re-layout with Flip whenever the visible set changes.
  const flipState = useRef<ReturnType<typeof Flip.getState> | null>(null);
  const captureFlip = () => {
    if (listRef.current && !matchMedia('(prefers-reduced-motion: reduce)').matches) {
      flipState.current = Flip.getState(listRef.current.querySelectorAll('.vine-node'));
    }
  };
  useEffect(() => {
    if (flipState.current) {
      Flip.from(flipState.current, { duration: 0.5, ease: 'power2.inOut', stagger: 0.02, absoluteOnLeave: true, onComplete: () => ScrollTrigger.refresh() });
      flipState.current = null;
    }
  }, [visible]);

  // Vine draws itself as you scroll.
  useEffect(() => {
    const path = vineRef.current;
    if (!path || matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    const len = path.getTotalLength();
    path.style.strokeDasharray = `${len}`;
    path.style.strokeDashoffset = `${len}`;
    const tween = gsap.to(path, {
      strokeDashoffset: 0,
      ease: 'none',
      scrollTrigger: { trigger: path.closest('.vine-wrap'), start: 'top 75%', end: 'bottom 60%', scrub: 0.6 },
    });
    return () => {
      tween.scrollTrigger?.kill();
      tween.kill();
    };
  }, [visible.length]);

  const wrap = (fn: () => void) => () => {
    captureFlip();
    fn();
  };

  return (
    <div>
      <div
        className="sticky top-16 z-30 -mx-4 mb-10 flex flex-wrap items-center gap-3 px-4 py-3 md:mx-0 md:rounded-full md:px-5"
        style={{ background: 'color-mix(in srgb, var(--canvas) 88%, transparent)', backdropFilter: 'blur(12px)' }}
      >
        <label className="min-w-40 flex-1">
          <span className="sr-only">Search releases</span>
          <input
            type="search"
            name="release-search"
            autoComplete="off"
            spellCheck={false}
            placeholder="Search versions or notes…"
            value={query}
            onChange={(e) => {
              captureFlip();
              setQuery(e.target.value);
            }}
            className="w-full rounded-full border px-4 py-2 text-sm"
            style={{ background: 'var(--surface)', borderColor: 'color-mix(in srgb, var(--ink) 14%, transparent)', color: 'var(--ink)' }}
          />
        </label>
        <div role="group" aria-label="Filter releases" className="flex flex-wrap gap-1.5">
          {FILTERS.map((f) => (
            <button
              key={f}
              type="button"
              onClick={wrap(() => setFilter(f))}
              aria-pressed={filter === f}
              className="rounded-full px-3 py-1.5 text-xs font-bold"
              style={
                filter === f
                  ? { background: 'var(--brand)', color: 'var(--on-brand)' }
                  : { background: 'var(--surface)', color: 'var(--ink-muted)', border: '1px solid color-mix(in srgb, var(--ink) 12%, transparent)' }
              }
            >
              {f}
            </button>
          ))}
        </div>
        {releases.some((r) => r.prerelease) && (
          <label className="flex items-center gap-2 text-xs font-bold text-ink-muted">
            <input type="checkbox" checked={beta} onChange={wrap(() => setBeta(!beta))} /> Beta
          </label>
        )}
        <button
          type="button"
          onClick={wrap(() => setOldestFirst(!oldestFirst))}
          className="rounded-full border px-3 py-1.5 text-xs font-bold"
          style={{ borderColor: 'color-mix(in srgb, var(--ink) 14%, transparent)', color: 'var(--ink-muted)' }}
        >
          {oldestFirst ? 'Oldest first ↑' : 'Newest first ↓'}
        </button>
        {stable.length > 1 && (
          <label className="flex items-center gap-2 text-xs font-bold text-ink-muted">
            What's new since my version?
            <select
              value={mine}
              onChange={(e) => {
                captureFlip();
                setMine(e.target.value);
              }}
              className="rounded-full border px-3 py-1.5"
              style={{ background: 'var(--surface)', borderColor: 'color-mix(in srgb, var(--ink) 14%, transparent)', color: 'var(--ink)' }}
            >
              <option value="">I have…</option>
              {stable.slice(1).map((r) => (
                <option key={r.tag} value={r.version}>
                  v{r.version}
                </option>
              ))}
            </select>
          </label>
        )}
      </div>

      {combined && (
        <section className="mb-12 rounded-[var(--radius)] border p-6 !py-6" style={{ background: 'var(--surface)', borderColor: 'var(--brand)' }}>
          <h2 className="mt-0 text-2xl">
            {combined.count} release{combined.count > 1 ? 's' : ''} since v{mine} 🌱
          </h2>
          {(['new', 'fixes', 'design', 'other'] as const).map((key) =>
            combined[key].length ? (
              <div key={key} className="mt-3">
                <h3 className="m-0 text-sm font-bold uppercase tracking-wide text-ink-muted">
                  {{ new: '✨ New', fixes: '🐛 Fixes', design: '🎨 Design', other: 'Other' }[key]}
                </h3>
                <ul className="mb-0 mt-1 list-disc pl-5 text-sm text-ink-muted">
                  {combined[key].map((b) => (
                    <li key={b}>{b}</li>
                  ))}
                </ul>
              </div>
            ) : null,
          )}
          <a
            href={combined.latest.apkUrl ?? combined.latest.detailUrl}
            className="mt-5 inline-block rounded-full px-6 py-2.5 font-bold no-underline"
            style={{ background: 'var(--brand)', color: 'var(--on-brand)' }}
          >
            Update to v{combined.latest.version}
          </a>
        </section>
      )}

      <div className="vine-wrap relative">
        <svg className="absolute left-4 top-0 hidden h-full w-16 md:block" aria-hidden="true" preserveAspectRatio="none" viewBox="0 0 64 1000">
          <path
            ref={vineRef}
            d="M32 0 C 12 120, 52 200, 32 320 C 12 440, 52 520, 32 640 C 12 760, 52 840, 32 1000"
            fill="none"
            stroke="var(--leaf-mid)"
            strokeWidth="3"
            strokeLinecap="round"
          />
        </svg>
        <div ref={listRef} className="grid gap-8 md:pl-24">
          {visible.map((r) => (
            <div key={r.tag} className="vine-node relative">
              <span
                className="absolute -left-[4.5rem] top-6 hidden size-10 place-items-center rounded-full text-xl md:grid"
                style={{ background: 'var(--surface-alt)', boxShadow: r.tag === latestTag ? '0 0 16px var(--brand)' : 'none' }}
                aria-hidden="true"
              >
                {KIND_ICON[r.kind]}
              </span>
              <ReleaseCard r={r} latest={r.tag === latestTag} />
            </div>
          ))}
          {visible.length === 0 && (
            <p className="rounded-[var(--radius)] border border-dashed p-10 text-center text-ink-muted" style={{ borderColor: 'color-mix(in srgb, var(--ink) 20%, transparent)' }}>
              Nothing sprouted for that filter 🥀 Try clearing the search.
            </p>
          )}
          {releases.length === 1 && visible.length === 1 && (
            <p className="m-0 text-center text-sm font-bold text-ink-muted">The first seed 🌱 · more growing soon</p>
          )}
        </div>
      </div>
    </div>
  );
}
