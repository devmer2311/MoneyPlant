# Money Plant website

Static Astro + React website for the Money Plant Android app. The existing five themes, bundled fonts, real app screenshots, garden identity and release vine are retained.

## Local development

```sh
cd site
npm ci
npm run dev
npm test
npm run check
npm run build
npm run preview
```

On restricted Windows sandboxes, Vite/esbuild may need execution outside the sandbox to resolve already-installed dependencies. This does not require reinstalling them.

## Product content

The published APK currently has local finance, local splits and backup/restore. SQLite is in development in this checkout. Username sharing, offline shared-split synchronization and device transfer are planned; keep those labels until the features actually ship. The website is not a backend implementation.

- Home: a direct Android download, three feature chapters, local/planned sharing distinction, two SVG storyboards, calculator, latest notes and FAQ.
- Features: desktop sticky phone, mobile vertical scrolling that moves a horizontal sequence. No wheel/touch interception. Reduced-motion, short viewport and no-JavaScript modes use readable stacked chapters.
- Storyboards: five scenes each for username sharing and local backup, automatic 3.5-second looping scenes and full transcripts. There are no playback buttons; reduced-motion uses static content. Illustrations are not screenshots of unreleased features.
- Releases: searchable, filterable timeline; static version detail pages; RSS and generated Open Graph images.
- Install: APK instructions, checksum commands for each platform, troubleshooting and backup story.
- Roadmap: explicit development/planned/shipped states with no invented percentages or dates.

## One release model

`src/lib/release-model.ts` is shared by build and browser. GitHub public Releases is authoritative for versions, dates, assets and digests. Drafts are excluded. Stable releases exclude both GitHub prereleases and SemVer prerelease suffixes; versions are compared numerically, not by publication time or string sorting.

Only a single universal versioned APK whose filename, release tag and exact GitHub download path agree is offered. An absent, ambiguous or mismatched APK produces an unavailable message, never an older file under a newer version. The mutable `latest/download/money-plant.apk` alias is not used by the website.

`src/lib/releases.ts` loads all API pages at build time, with one ten-second deadline and a 50-page limit. It never rewrites source files. Local builds fall back to a validated checked-in raw snapshot. Production CI sets `REQUIRE_FRESH_RELEASES=1` and fails rather than deploying a silently stale build.

Browser React islands share one in-memory request cache with a 60-second TTL. They revalidate with `cache: no-cache`, update the entire release record together, retry while visible, and recheck when returning to a tab. There is no persistent session cache or random cache-busting URL. Offline/rate-limit/error responses keep last-known data with an explicit warning and GitHub link. Published releases with no APK are still shown, with download unavailable.

A release discovered after deployment appears immediately in the timeline with full notes. Until its static detail page is built, links go to the timeline, not a nonexistent route. Static detail pages, RSS and search-engine metadata update on deployment.

## Human release notes

`src/data/changelog.json` is the single hand-authored source for known releases. Each tag has a title and arrays: `new`, `fixes`, `design` (displayed as Improvements), `privacy`, `backup`, `sync`, `other`. Use only real changes; leave empty categories empty.

`scripts/release-notes.mjs TAG OUTPUT` validates that entry and emits the marked GitHub release body. The website can parse that body for a future release before redeploying. Unmarked auto-generated PR/commit lists are ignored. All notes are rendered as escaped text. A fixes-only release gets a modest cleanup summary; version number alone never invents features.

Existing v1.0.1 / v2.0.0 / v2.0.1 notes were reconstructed from repository source history and README, not empty GitHub generated notes.

## Publishing a future Android release

Prepare the app version in `versions/app.yaml` on `dev`, synchronize pubspec with `python tool/component_version.py app --sync-pubspec`, and add matching human notes. Dev builds a debug APK artifact. Merge into beta to publish a signed prerelease, or promote dev/beta into main to publish a stable APK. Beta release notes use the exact vX.Y.Z-beta.BUILD tag. No workflow bumps versions or commits files.

Website builds are independently gated by `versions/site.yaml`. Dev produces a static artifact; main deploys it. App publication does not dispatch a site build. Browser release panels discover new releases, while static release details and RSS require a site version bump/deployment.

See [the pipeline guide](../PIPELINE.md) for branch policy, version examples, secrets, retry behavior and deployment verification. To maintain the local fallback snapshot explicitly, run `node scripts/refresh-releases.mjs`, then `npm test` and review the diff.

## Configuration

| Variable / secret | Where | Purpose |
| --- | --- | --- |
| `GITHUB_TOKEN` | Build/maintenance only | Optional locally, supplied by CI to avoid the low anonymous API quota. Never use a PUBLIC-prefixed token. |
| `REQUIRE_FRESH_RELEASES=1` | Production site build | Fail on API errors rather than silently use fallback. |
| `SITE_URL` | Build | Canonical site origin; default https://moneyplantbydev.pages.dev |
| `SITE_BASE` | Build | Optional hosting subpath; empty by default. |
| `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` | CI secrets | Existing Pages deployment credentials. |
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` | Android CI secrets | Existing release signing credentials. |

Browser requests need no token. Do not ship build secrets to client JavaScript. No backend or database is required by this website.

See [implementation and QA report](IMPLEMENTATION.md) for the audit, download trace, changed files and remaining limitations.
