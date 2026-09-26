// Demo GardenData used to seed the Flutter web app before capturing the site's
// phone-mock screenshots (scripts/capture-screens.md). Prints the JSON blob for
// a given theme pack: node scripts/seed-data.mjs sakura
const iso = (d) => d.toISOString();
const day = (n) => new Date(Date.now() - n * 86_400_000);

const entry = (id, title, amount, daysAgo, category, kind = 'expense', extra = {}) => ({
  id, title, amount, date: iso(day(daysAgo)), createdAt: iso(day(daysAgo)),
  category, kind, notes: '', splitId: null, goalId: null, importRef: null,
  recurringId: null, paymentId: null, ...extra,
});

export function seed(themePack = 'garden') {
  return {
    schemaVersion: 2,
    themePack,
    theme: 'dark',
    currency: 'INR',
    appLock: false,
    profile: { displayName: 'Dev', upiId: 'dev@upi', payeeName: 'Dev', includeQr: true, includeUpiLink: true },
    groups: [], groupSettlements: [], recurring: [], budgets: { Food: 1200000, Travel: 600000 },
    importMappings: {},
    entries: [
      entry('e1', 'Salary', 6250000, 24, 'Other', 'income'),
      entry('e2', 'Rent', 1850000, 22, 'Home'),
      entry('e3', 'Groceries at DMart', 342750, 18, 'Food'),
      entry('e4', 'Metro card top-up', 50000, 15, 'Travel'),
      entry('e5', 'Dinner at Karavalli', 486300, 12, 'Food', 'expense', { splitId: 's1' }),
      entry('e6', 'Electricity bill', 178400, 9, 'Home'),
      entry('e7', 'Movie night', 96000, 7, 'Fun'),
      entry('e8', 'Chai and vada pav', 12500, 4, 'Food'),
      entry('e9', 'Cab to airport', 84200, 2, 'Travel'),
      entry('e10', 'Freelance payout', 1500000, 1, 'Other', 'income'),
    ],
    tasks: [
      { id: 't1', title: 'Collect cab fare from Rohan', date: iso(day(-2)), amount: 42100, direction: 'collect', completed: false, notes: '', personId: 'p3' },
    ],
    goals: [{ id: 'g1', title: 'Goa trip', target: 4000000, date: iso(day(-60)), icon: '🌴' }],
    contributions: [
      { id: 'c1', goalId: 'g1', amount: 1500000, date: iso(day(20)) },
      { id: 'c2', goalId: 'g1', amount: 800000, date: iso(day(6)) },
    ],
    people: [
      { id: 'p1', name: 'Aarav' },
      { id: 'p2', name: 'Meera' },
      { id: 'p3', name: 'Rohan' },
    ],
    splits: [
      {
        id: 's1', title: 'Dinner at Karavalli', total: 486300, date: iso(day(12)),
        method: 'equal', portions: { self: 121575, p1: 121575, p2: 121575, p3: 121575 },
        payerId: 'self', groupId: null, items: [], notes: '',
      },
      {
        id: 's2', title: 'Weekend villa', total: 1200000, date: iso(day(5)),
        method: 'shares', portions: { self: 400000, p1: 400000, p2: 400000 },
        payerId: 'p1', groupId: null, items: [], notes: '',
      },
    ],
    payments: [
      { id: 'pay1', splitId: 's1', personId: 'p1', amount: 121575, date: iso(day(10)), note: 'UPI' },
    ],
    activity: { [iso(day(1)).slice(0, 10)]: iso(day(1)) },
  };
}

if (process.argv[1] && import.meta.url.endsWith(process.argv[1].replace(/\\/g, '/').split('/').pop())) {
  console.log(JSON.stringify(seed(process.argv[2] ?? 'garden')));
}
