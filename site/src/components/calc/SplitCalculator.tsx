// Try-it island: a real split calculator running the app's exact paise maths.
import { useMemo, useState } from 'react';
import { allocateSplit, money, parseMoney, splitMessage, type SplitMethod } from '../../lib/split.ts';

type Item = { id: number; name: string; price: string; people: number[] };

const METHODS: { id: SplitMethod | 'items'; label: string }[] = [
  { id: 'equal', label: 'Equal' },
  { id: 'percentage', label: 'Percent' },
  { id: 'shares', label: 'Shares' },
  { id: 'items', label: 'Items' },
];
const CHIP_COLORS = ['var(--chart-1)', 'var(--chart-2)', 'var(--chart-3)', 'var(--chart-4)', 'var(--chart-5)', 'var(--chart-6)'];

let itemId = 1;

export default function SplitCalculator() {
  const [people, setPeople] = useState(['You', 'Aarav', 'Meera']);
  const [newName, setNewName] = useState('');
  const [method, setMethod] = useState<SplitMethod | 'items'>('equal');
  const [amount, setAmount] = useState('1200');
  const [weights, setWeights] = useState<Record<string, string>>({});
  const [items, setItems] = useState<Item[]>([
    { id: 0, name: 'Biryani', price: '540', people: [0, 1, 2] },
  ]);
  const [copied, setCopied] = useState<'no' | 'yes' | 'manual'>('no');

  const result = useMemo((): { shares: number[]; total: number } | { error: string } => {
    try {
      if (method === 'items') {
        const totals = people.map(() => 0);
        let total = 0;
        for (const item of items) {
          const price = parseMoney(item.price || '0');
          total += price;
          const owners = item.people.filter((i) => i < people.length);
          if (!owners.length) throw new Error(`Pick who shared "${item.name || 'each item'}".`);
          if (owners.length === 1) totals[owners[0]!]! += price;
          else {
            const parts = allocateSplit(price, 'equal', owners.map(() => 1));
            owners.forEach((p, i) => (totals[p]! += parts[i]!));
          }
        }
        if (total <= 0) throw new Error('Add at least one item with a price.');
        return { shares: totals, total };
      }
      const total = parseMoney(amount);
      const w =
        method === 'equal'
          ? people.map(() => 1)
          : people.map((p) => {
              const v = Number(weights[p] ?? '');
              if (!Number.isFinite(v) || v < 0) throw new Error(`Set a ${method === 'percentage' ? 'percentage' : 'share'} for ${p}.`);
              return method === 'percentage' ? Math.round(v * 100) : Math.round(v);
            });
      return { shares: allocateSplit(total, method, w), total };
    } catch (e) {
      return { error: (e as Error).message };
    }
  }, [method, amount, people, weights, items]);

  const ok = 'shares' in result;

  const addPerson = () => {
    const name = newName.trim();
    if (!name || people.some((p) => p.toLowerCase() === name.toLowerCase()) || people.length >= 6) return;
    setPeople([...people, name]);
    setNewName('');
  };

  const share = async () => {
    if (!ok) return;
    const text = splitMessage({
      title: 'Dinner out',
      total: result.total,
      payer: people[0]!,
      people: people.map((name, i) => ({ name, amount: result.shares[i]! })),
    });
    try {
      await navigator.clipboard.writeText(text);
      setCopied('yes');
    } catch {
      setCopied('manual');
      // Visible fallback: select the text in a prompt-like textarea.
      const ta = document.createElement('textarea');
      ta.value = text;
      ta.style.cssText = 'position:fixed;inset:auto 1rem 1rem 1rem;z-index:60;height:10rem;';
      document.body.appendChild(ta);
      ta.select();
      ta.addEventListener('blur', () => ta.remove());
    }
    setTimeout(() => setCopied('no'), 3000);
  };

  const inputStyle = {
    background: 'var(--canvas)',
    border: '1px solid color-mix(in srgb, var(--ink) 16%, transparent)',
    color: 'var(--ink)',
  } as const;

  return (
    <div className="rounded-[var(--radius)] border p-6 md:p-8" style={{ background: 'var(--surface)', borderColor: 'color-mix(in srgb, var(--ink) 10%, transparent)' }}>
      <div className="flex flex-wrap gap-2" role="tablist" aria-label="Split method">
        {METHODS.map((m) => (
          <button
            key={m.id}
            type="button"
            role="tab"
            aria-selected={method === m.id}
            onClick={() => setMethod(m.id)}
            className="rounded-full px-4 py-1.5 text-sm font-bold"
            style={
              method === m.id
                ? { background: 'var(--brand)', color: 'var(--on-brand)' }
                : { background: 'var(--surface-alt)', color: 'var(--ink-muted)' }
            }
          >
            {m.label}
          </button>
        ))}
      </div>

      {method !== 'items' && (
        <label className="mt-5 block max-w-56">
          <span className="mb-1 block text-sm font-bold">Bill amount (₹)</span>
          <input inputMode="decimal" name="bill-amount" autoComplete="off" value={amount} onChange={(e) => setAmount(e.target.value)} className="w-full rounded-xl px-4 py-2.5 text-lg font-bold" style={inputStyle} />
        </label>
      )}

      <div className="mt-5">
        <span className="mb-2 block text-sm font-bold">Who's in?</span>
        <div className="flex flex-wrap items-center gap-2">
          {people.map((p, i) => (
            <span key={p} className="flex items-center gap-1.5 rounded-full py-1 pl-3 pr-1.5 text-sm font-bold" style={{ background: CHIP_COLORS[i % 6], color: 'var(--on-receive)' }}>
              {p}
              {people.length > 2 && (
                <button
                  type="button"
                  aria-label={`Remove ${p}`}
                  onClick={() => setPeople(people.filter((x) => x !== p))}
                  className="grid size-5 place-items-center rounded-full text-xs"
                  style={{ background: 'rgba(0,0,0,0.15)' }}
                >
                  ✕
                </button>
              )}
            </span>
          ))}
          {people.length < 6 && (
            <span className="flex items-center gap-1">
              <label>
                <span className="sr-only">Add a person</span>
                <input
                  value={newName}
                  name="person-name"
                  autoComplete="off"
                  spellCheck={false}
                  onChange={(e) => setNewName(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && addPerson()}
                  placeholder="Add name"
                  className="w-28 rounded-full px-3 py-1.5 text-sm"
                  style={inputStyle}
                />
              </label>
              <button type="button" onClick={addPerson} aria-label="Add person" className="grid size-8 place-items-center rounded-full font-bold" style={{ background: 'var(--surface-alt)', color: 'var(--ink)' }}>
                +
              </button>
            </span>
          )}
        </div>
      </div>

      {(method === 'percentage' || method === 'shares') && (
        <div className="mt-4 flex flex-wrap gap-3">
          {people.map((p) => (
            <label key={p} className="text-sm">
              <span className="mb-1 block font-bold">{p}{method === 'percentage' ? ' %' : ' shares'}</span>
              <input
                inputMode="decimal"
                name={`weight-${p}`}
                autoComplete="off"
                value={weights[p] ?? ''}
                onChange={(e) => setWeights({ ...weights, [p]: e.target.value })}
                placeholder={method === 'percentage' ? '33.33' : '1'}
                className="w-24 rounded-xl px-3 py-2"
                style={inputStyle}
              />
            </label>
          ))}
        </div>
      )}

      {method === 'items' && (
        <div className="mt-4 grid gap-3">
          {items.map((item) => (
            <div key={item.id} className="flex flex-wrap items-center gap-2 rounded-2xl p-3" style={{ background: 'var(--surface-alt)' }}>
              <label>
                <span className="sr-only">Item name</span>
                <input value={item.name} name={`item-name-${item.id}`} autoComplete="off" spellCheck={false} placeholder="Item" onChange={(e) => setItems(items.map((x) => (x.id === item.id ? { ...x, name: e.target.value } : x)))} className="w-32 rounded-xl px-3 py-1.5 text-sm" style={inputStyle} />
              </label>
              <label>
                <span className="sr-only">Price</span>
                <input value={item.price} name={`item-price-${item.id}`} autoComplete="off" placeholder="₹" inputMode="decimal" onChange={(e) => setItems(items.map((x) => (x.id === item.id ? { ...x, price: e.target.value } : x)))} className="w-20 rounded-xl px-3 py-1.5 text-sm" style={inputStyle} />
              </label>
              <span className="flex flex-wrap gap-1">
                {people.map((p, pi) => (
                  <button
                    key={p}
                    type="button"
                    aria-pressed={item.people.includes(pi)}
                    onClick={() =>
                      setItems(
                        items.map((x) =>
                          x.id === item.id ? { ...x, people: x.people.includes(pi) ? x.people.filter((v) => v !== pi) : [...x.people, pi] } : x,
                        ),
                      )
                    }
                    className="rounded-full px-2.5 py-1 text-xs font-bold"
                    style={item.people.includes(pi) ? { background: CHIP_COLORS[pi % 6], color: 'var(--on-receive)' } : { background: 'var(--canvas)', color: 'var(--ink-muted)' }}
                  >
                    {p}
                  </button>
                ))}
              </span>
              {items.length > 1 && (
                <button type="button" aria-label={`Remove ${item.name || 'item'}`} onClick={() => setItems(items.filter((x) => x.id !== item.id))} className="ml-auto text-sm text-ink-muted">
                  ✕
                </button>
              )}
            </div>
          ))}
          <button
            type="button"
            onClick={() => setItems([...items, { id: itemId++, name: '', price: '', people: [] }])}
            className="justify-self-start rounded-full border px-4 py-1.5 text-sm font-bold"
            style={{ borderColor: 'color-mix(in srgb, var(--ink) 18%, transparent)', color: 'var(--ink)' }}
          >
            + Add item
          </button>
        </div>
      )}

      <div className="mt-6 border-t pt-5" style={{ borderColor: 'color-mix(in srgb, var(--ink) 10%, transparent)' }} aria-live="polite">
        {ok ? (
          <>
            <div className="flex h-5 w-full overflow-hidden rounded-full" aria-hidden="true">
              {result.shares.map((s, i) => (
                <span
                  key={people[i]}
                  className="h-full transition-[width] duration-500"
                  style={{ width: `${(s / result.total) * 100}%`, background: CHIP_COLORS[i % 6] }}
                />
              ))}
            </div>
            <ul className="m-0 mt-4 grid list-none gap-1.5 p-0">
              {people.map((p, i) => (
                <li key={p} className="flex justify-between text-sm font-bold" style={{ fontVariantNumeric: 'tabular-nums' }}>
                  <span className="flex items-center gap-2">
                    <span className="inline-block size-2.5 rounded-full" style={{ background: CHIP_COLORS[i % 6] }} aria-hidden="true" />
                    {p}
                  </span>
                  <span>{money(result.shares[i]!)}</span>
                </li>
              ))}
            </ul>
            <p className="m-0 mt-2 text-right text-sm text-ink-muted" style={{ fontVariantNumeric: 'tabular-nums' }}>
              Total {money(result.total)} · every paise accounted for
            </p>
            <button type="button" onClick={share} className="mt-4 rounded-full px-6 py-2.5 font-bold" style={{ background: 'var(--brand)', color: 'var(--on-brand)' }}>
              {copied === 'yes' ? 'Copied ✓' : copied === 'manual' ? 'Select the text below' : 'Share this split'}
            </button>
          </>
        ) : (
          <p className="m-0 text-sm font-bold" style={{ color: 'var(--chart-1)' }} role="status">
            {result.error}
          </p>
        )}
      </div>
    </div>
  );
}
