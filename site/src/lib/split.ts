// Direct port of the app's paise-exact split maths (lib/core/models.dart):
// largest-remainder allocation, same validation, same messages.
export type SplitMethod = 'equal' | 'custom' | 'percentage' | 'shares';

export function parseMoney(value: string): number {
  const input = value.trim().replaceAll(',', '');
  if (!/^\d{1,10}(\.\d{1,2})?$/.test(input)) {
    throw new Error('Enter an amount with up to two decimal places.');
  }
  const [whole, frac] = input.split('.');
  const result = Number(whole) * 100 + (frac ? Number(frac.padEnd(2, '0')) : 0);
  if (result <= 0) throw new Error('Amount must be greater than zero.');
  return result;
}

export function allocateSplit(total: number, method: SplitMethod, weights: number[]): number[] {
  if (total <= 0 || weights.length < 2 || weights.some((v) => v < 0)) {
    throw new Error('Add at least two people and a positive total.');
  }
  if (method === 'custom') {
    if (weights.reduce((a, b) => a + b, 0) !== total) {
      throw new Error('Custom amounts must add up to the bill.');
    }
    return [...weights];
  }
  const values = method === 'equal' ? weights.map(() => 1) : weights;
  const sum = values.reduce((a, b) => a + b, 0);
  if (sum <= 0 || (method === 'percentage' && sum !== 10000)) {
    throw new Error('Percentages must total 100%; shares must be positive.');
  }
  const result = values.map((v) => Math.floor((total * v) / sum));
  const order = values
    .map((_, i) => i)
    .sort((a, b) => {
      const diff = ((total * values[b]!) % sum) - ((total * values[a]!) % sum);
      return diff === 0 ? a - b : diff;
    });
  const remainder = total - result.reduce((a, b) => a + b, 0);
  for (let i = 0; i < remainder; i++) result[order[i]!]!++;
  return result;
}

export function money(paise: number, currency = 'INR'): string {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
  }).format(paise / 100);
}

/** The same WhatsApp-style summary the app shares (features/reports.dart). */
export function splitMessage(opts: {
  title: string;
  total: number;
  payer: string;
  people: { name: string; amount: number }[];
  date?: Date;
}): string {
  const date = (opts.date ?? new Date()).toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });
  const lines = opts.people.map(
    (p) => `${p.name} — ${money(p.amount)} · ${p.name === opts.payer ? 'Paid' : `${money(p.amount)} pending`}`,
  );
  return `🌱 Money Plant · Split summary\n\n${opts.title}\n${date}\nTotal: ${money(opts.total)}\nPaid by: ${opts.payer}\n\n${lines.join('\n')}\n\nA little clearer. All together.`;
}
