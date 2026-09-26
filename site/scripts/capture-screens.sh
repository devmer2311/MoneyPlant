#!/usr/bin/env bash
# Captures app screenshots for the site's phone mock: 5 themes x 5 screens.
# Prereqs: `flutter build web` done, `py -m http.server 8123 --directory build/web`
# running at the repo root, and a playwright session:
#   playwright-cli -s=app open --device="iPhone 13" http://localhost:8123/
# Run from /site: bash scripts/capture-screens.sh [theme ...]
set -euo pipefail
export MSYS2_ARG_CONV_EXCL="*"

themes=("${@:-garden sakura neon mango ocean}")
[ $# -eq 0 ] && themes=(garden sakura neon mango ocean)

pw() { playwright-cli -s=app "$@"; }

shot() { # shot <theme> <name>
  mkdir -p "src/assets/screens/$1"
  pw screenshot --hires --filename="src/assets/screens/$1/$2.png" >/dev/null
  echo "  $1/$2.png"
}

for theme in "${themes[@]}"; do
  echo "== $theme =="
  node -e "
    import('./scripts/seed-data.mjs').then((m) => {
      const enc = JSON.stringify(JSON.stringify(m.seed('$theme')));
      require('fs').writeFileSync('.screens/set-seed.js',
        'async page => { await page.evaluate((v) => { localStorage.setItem(\"flutter.money_plant.garden.v1\", v); localStorage.setItem(\"money_plant.garden.v1\", v); }, ' + JSON.stringify(enc) + '); }');
    });"
  pw run-code --filename=.screens/set-seed.js >/dev/null
  pw reload >/dev/null; sleep 8
  pw eval "() => document.querySelector('flt-semantics-placeholder')?.click()" >/dev/null; sleep 2
  shot "$theme" overview
  pw click "getByRole('button', { name: 'Insights Insights' })" >/dev/null; sleep 2.5
  shot "$theme" insights
  pw click "getByRole('button', { name: 'Splits Splits' })" >/dev/null; sleep 2
  shot "$theme" splits
  pw click "getByRole('checkbox', { name: 'A Aarav' })" >/dev/null; sleep 2
  shot "$theme" person
  pw go-back >/dev/null; sleep 1.5
  pw click "getByRole('button', { name: 'Settings' })" >/dev/null; sleep 2
  shot "$theme" settings
  pw go-back >/dev/null; sleep 1.5
done
echo "done"
