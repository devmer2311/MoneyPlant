# Money Plant website

The showcase and download site for the Money Plant Android app, built with
Astro 5 + React 19 + Tailwind v4 + GSAP, deployed to Cloudflare Pages at
<https://moneyplantbydev.pages.dev/>.

## Local development

```bash
cd site
npm install
npm run dev        # http://localhost:4321/
npm test           # vitest unit tests (data layer + split maths)
npm run build      # static build into dist/ (uses the live GitHub API, falls
                   # back to src/data/releases.snapshot.json offline)
npm run preview    # serve the built site
```

`GITHUB_TOKEN` is optional locally; CI passes it to avoid API rate limits.

## How deploys happen

`.github/workflows/site.yml` builds and deploys to Cloudflare Pages with
Wrangler on:

- every push to `main` touching `site/**`,
- a `workflow_dispatch` fired by the release workflow after each release
  (releases created with `GITHUB_TOKEN` cannot trigger `on: release`, hence the
  dispatch),
- a weekly cron that refreshes download counts and relative dates.

One-time setup:

1. Create the Pages project once: `npx wrangler pages project create moneyplantbydev`
   (or in the Cloudflare dashboard → Workers & Pages → Create → Pages →
   Direct Upload). Do **not** connect it to Git; the GitHub Action deploys.
2. Add two repo secrets (Settings → Secrets and variables → Actions):
   - `CLOUDFLARE_ACCOUNT_ID` — dashboard → Workers & Pages → right sidebar.
   - `CLOUDFLARE_API_TOKEN` — dashboard → My Profile → API Tokens → Create,
     with the **Cloudflare Pages: Edit** permission.

Deploy manually from your machine with the same command CI uses:

```bash
cd site && npm run build && npx wrangler pages deploy dist --project-name=moneyplantbydev --branch=main
```

## Custom domain

Add the domain in Cloudflare dashboard → the Pages project → Custom domains,
then rebuild with the matching URL so canonicals, OG images, RSS and the
sitemap follow:

```bash
SITE_URL=https://moneyplant.example npm run build
```

(Also update `public/robots.txt` and the `SITE_URL` env in `site.yml`.
`SITE_BASE` stays empty unless you host under a subpath.)

## Updating content

- **Roadmap:** edit `src/data/roadmap.json`. `status` is `now`, `next`,
  `ideas` or `shipped`; `progress` (0-100) shows a bar on `now` cards;
  `release` links a shipped card to its release page.
- **Theme tokens:** generated from the app's theme packs. If the app's
  palettes change, mirror them in `scripts/gen-tokens.mjs` and run
  `npm run gen:tokens`.
- **App screenshots:** `bash scripts/capture-screens.sh` re-captures all 5
  themes from the Flutter web build (instructions in the script header).
- **Releases:** nothing to do. The build pulls GitHub Releases and writes
  `src/data/releases.snapshot.json` as the offline fallback; commit the
  refreshed snapshot when it changes.
