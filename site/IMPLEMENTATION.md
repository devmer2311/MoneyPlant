# Website audit, implementation and QA

Date: 28 September 2026. The verification below records local checks before the authorized website release. Deployment status is recorded by GitHub Actions and /site-version.json.

## Architecture and audit

The existing website is an Astro 5 static site with React islands, Tailwind 4, CSS theme tokens, locally bundled fonts and optimized screenshots. It is deployed through the existing Cloudflare Pages workflow. Public routes are home, releases, per-tag release detail, install, roadmap and 404, plus RSS, sitemap, manifest and generated Open Graph images.

The audit read the site components, routes, data loaders, theme/animation code, GitHub workflows, app version/release history and settings backup implementation. The deployed home, release center, install and roadmap were inspected in the browser. The existing Garden/Sakura/Neon/Mango/Ocean palettes, font families, app imagery, plant motif and release timeline provided the visual foundation.

Findings before changes:

| Area | Evidence / issue |
| --- | --- |
| Hero/download | A blocking intro and cycling oversized text delayed/competed with the CTA. Desktop primary clicks opened a QR interaction instead of downloading. |
| Responsive features | Desktop had a sticky screen; mobile simply stacked long chapters. The supplied screenshot showed the phone left-aligned with excess space. |
| Navigation | Main navigation disappeared on mobile. Theme buttons were small; repeated theme rebuilds attached duplicate mode-toggle listeners. |
| Privacy | “No servers” and “nothing ever leaves” conflicted with update checks and planned optional sharing. SQLite, username sharing and transfer needed accurate release-status labels. |
| Feature hierarchy | Six equal chapters with tall scroll spacing hid the finance/splits/privacy grouping. Global section padding also inflated nested roadmap and release sections. |
| Releases | Publication date decided order. APK selection took the first filename matching a loose regex without checking its version against the tag. |
| Browser freshness | Session storage had no expiry. Only version text and selected links changed, leaving dates, size, checksum, QR, cards and details inconsistent. |
| Changelog | Current GitHub release bodies only contained generated comparison links. The latest card inferred “first public build” whenever bullets were empty. |
| Failure states | Home threw when there was no release. Snapshot data was cast rather than validated, and successful builds silently overwrote tracked snapshot source. |
| Install guide | Recommended uninstalling or bypassing security warnings; combined Linux/macOS checksum commands incorrectly. |
| Roadmap | Claimed shipped update checks were still in progress and listed inaccurate shipped-version links and unverified percentages. |
| Motion/accessibility | Custom dialogs lacked native focus management; infinite text/cursor/decorative effects added cost. Several listeners/timers were not cleaned up on navigation. |
| SEO | Existing titles/canonical/OG/RSS/icons were present, but product claims and date presentation needed correction. |

## Download investigation: confirmed facts, not a guessed historical cause

Source: [public GitHub Releases API](https://api.github.com/repos/devmer2311/MoneyPlant/releases?per_page=100), [v2.0.1 release](https://github.com/devmer2311/MoneyPlant/releases/tag/v2.0.1), the deployed site and its source code.

The live site showed v2.0.1 during the audit. The old mutable alias
`https://github.com/devmer2311/MoneyPlant/releases/latest/download/money-plant.apk`
redirected to the v2.0.1 alias asset, then GitHub’s release-assets host. Its redirect used `Cache-Control: no-cache`. The response was 200 with 74,595,585 bytes.

The versioned URL was downloaded locally:
`https://github.com/devmer2311/MoneyPlant/releases/download/v2.0.1/money-plant-v2.0.1%2B4.apk`.

| Check | Observed value |
| --- | --- |
| GitHub tag | v2.0.1 |
| Published | 2026-09-26T10:34:40Z |
| Filename | money-plant-v2.0.1+4.apk |
| Size | 74,595,585 bytes (71.1 MiB; UI uses conventional MB label) |
| Downloaded SHA-256 | 48aaa39c67a7ec6c6d28ce26a35cf1198fbd9548af4b101f55e4e739340cfa11 |
| GitHub versioned asset digest | Same SHA-256 |
| GitHub alias asset digest | Same SHA-256 |
| Embedded Android package | app.moneyplant.money_plant |
| Embedded versionName | 2.0.1 |
| Embedded versionCode | 4 |

The APK’s binary AndroidManifest.xml was inspected directly without installing/executing the APK. The downloaded file and small metadata report are in ignored `artifacts/`. The local machine did not have Android SDK aapt available; CI uses aapt for the future release gate.

**The older-APK symptom was not reproduced. Its exact historical cause cannot be established from the current release alone.** There is no evidence here that Cloudflare served old APK bytes, or that v2.0.1 was packaged with an older version. A prior downloaded file, its hash/embedded version, and the exact URL/time would be needed to establish that history.

Separately, the source proves real causes of inconsistent website state: indefinite session caching, partial metadata refresh, publication-order selection, mutable alias routing and unvalidated first-match APK selection. Those mechanisms were replaced; the report does not claim they prove which historical event the user saw.

## What changed

- A calmer hero answers what the app does, privacy/offline behavior and where to download. Direct Android downloads work on desktop and mobile.
- Three feature categories retain real app screenshots. Desktop keeps the sticky phone/side descriptions. Mobile vertical scrolling drives a horizontal three-chapter sequence; each chapter centers the phone over its description. Chapter controls allow direct navigation. There is no scroll-event cancellation or wheel hijacking.
- A clear local-versus-planned-online diagram explains personal records, custom people, selective shared splits, backups and future identity transfer. Local SQLite is labeled in development; online features remain labeled planned.
- Added original SVG/CSS illustrated stories with people and phones. They are animations, not videos or screenshots of unreleased UI.
- The five-scene username script: optional usernames → choose a bill → share selected split → queue offline → reconnect and sync.
- The five-scene backup script: new phone is empty → Mira gets frustrated → export a JSON backup → move the file → restore and check records. It uses the app’s actual Settings action names and explains replacement of destination data.
- Stories loop automatically every 3.5 seconds while visible, pause offscreen/background, use passive scene indicators, and have full text transcripts. Playback buttons have been removed. Reduced-motion disables automatic playback and decorative motion. Mobile scroll pinning is disabled for reduced-motion and very short viewports, preserving readable stacked content.
- Navigation is available at all sizes with native disclosure menus and comfortable touch targets. Escape closes menus and restores focus. Theme changes do not accumulate mode-toggle listeners.
- Release cards show version, absolute UTC publication date, real populated categories, matched Android asset and checksum. Latest status is textual, not color alone. Search, change-category filter, prerelease toggle, reset and empty states work.
- Release details use escaped plain-text notes. No arbitrary GitHub HTML or raw commit list is injected. Missing notes are described honestly. A fixes-only release has a cleanup summary without fake features.
- Install copy protects existing data and uses separate Windows/Linux/macOS hash commands.
- Existing metadata/icons/manifest/RSS/OG/sitemap remain. Added SoftwareApplication structured data without fake ratings or a stale softwareVersion.
- Removed blocking intro, mutable QR download path, false download-confirmation drawer, fabricated user stats, floating cursor and global keyboard shortcuts. The phone follows the selected theme without an endless auto-cycle. Removed the imported smooth-scrolling runtime.
- Roadmap status now matches source and published releases.

## Release and download design

GitHub is authoritative for version, publication date, APK URL/size and checksum. Authored `changelog.json` is authoritative for human wording. The future release-body generator emits the same categorized notes so a newly published version can show readable notes before the next site deployment.

The shared release validator orders numeric SemVer, excludes drafts and prereleases from the stable choice, validates the tag-matching universal APK and rejects ambiguous assets. It never promotes an older APK under a newer release label. Missing/ambiguous assets yield a clear unavailable state and GitHub fallback.

Build data and browser data use the same model. Browser requests are shared across islands and use a 60-second in-memory TTL and HTTP revalidation. Version, date, file, size, notes and digest render from one record. There is no permanent session cache. API timeout, rate limit or invalid responses retain last-known data with a warning. Empty valid lists have a no-release state.

Production builds require a successful fresh GitHub fetch. Offline local builds use the validated checked-in snapshot; normal builds never rewrite it. Static detail pages/RSS/SEO update at deployment. Releases discovered afterward show full notes in the live timeline and link there rather than to an unbuilt detail page.

## Future release publishing

See [README](README.md#publishing-a-future-android-release) for the complete maintainer sequence and configuration.

Independent app/site manifests now gate their respective workflows. Dev builds artifacts; only main publishes the verified Android release or deploys the site. App publication does not dispatch the site workflow. CI never bumps versions or commits. See [PIPELINE.md](../PIPELINE.md) for the current release process and recovery instructions.

Environment: optional build-only GITHUB_TOKEN, production REQUIRE_FRESH_RELEASES=1, existing SITE_URL/SITE_BASE, Cloudflare credentials and Android signing secrets. No browser secret or backend service is required. Never expose GITHUB_TOKEN with a PUBLIC prefix.

## Changed files

Existing app SQLite files and root plan.md predate this website task and were preserved.

Website updates:
- `src/components/SiteHeader.astro`, `SiteFooter.astro`
- `src/components/hero/Hero.astro`, `PhoneMock.astro`, `ThemeOrbs.astro`
- `src/components/story/Story.astro`
- `src/components/home/Privacy.astro`, `Faq.astro`; new `HowItWorks.astro`
- `src/components/releases/ReleasesExplorer.tsx`; new `DownloadPanel.tsx`, `ReleaseNotes.tsx`, `useReleases.ts`, render tests
- `src/layouts/Base.astro`, `src/styles/global.css`
- `src/pages/index.astro`, `install.astro`, `404.astro`, `releases/index.astro`, `releases/[tag].astro`, `releases.xml.ts`
- `src/lib/releases.ts`, `latest.ts`, `notes.ts`, `semver.ts`; new `release-model.ts`; corresponding tests
- `src/data/roadmap.json`; new `changelog.json`, `releases.raw.json`
- New `scripts/release-notes.mjs`, its test and `scripts/refresh-releases.mjs`
- `README.md`, this report

Replaced obsolete components/data: SeedButton, InstallDrawer, LatestReleaseCard, FinalCta, StatsMarquee, PunchIntro, Delight and the old normalized snapshot. Their necessary behavior is covered by the shared download panel, native navigation and current release model.

Release automation:
- `.github/workflows/build-release.yml`, `.github/workflows/site.yml`
- New `tool/verify_release.py`, `tool/test_verify_release.py`

## Validation

- Baseline: 13 website tests; Astro check clean.
- Updated suite: **35 tests passed**. Covers strict SemVer/prereleases, publication-order traps, mismatched/ambiguous/architecture-specific/unsafe assets, missing APK, malformed/empty responses, pagination, HTTP 403/404/429/500, snapshot fallback, strict production failure, shared cache expiry/recovery, escaped notes, fix-only/missing notes, server-rendered consistency and note generator.
- **Astro check: 49 files, zero errors/warnings/hints.**
- Production build succeeded: eight HTML routes plus feeds/metadata and eleven optimized WebP variants. No animation video downloads. Story behavior is small native JavaScript/SVG/CSS; React remains for dynamic release UI and calculator.
- Release metadata gate: two Python tests passed, including wrong name/build/package and missing metadata.
- Both modified workflow files parse as valid YAML. External signing/upload/deployment steps were not executed.
- All eight generated HTML pages passed an internal URL/fragment/asset existence scan; no mutable latest/download aliases remain in generated HTML.
- Browser: home at 320×700, 390×844, 768×1024 and 1440×1000; narrow-page checks for release list, latest/older detail, install, roadmap and 404. No horizontal document overflow or broken images in those checks.
- Browser: mobile menu and route navigation; back navigation; persisted theme; all five palettes in light mode; Garden dark; empty search/reset; fixes filter; release detail and exact versioned URL; mobile horizontal story entry/centered chapter; all manual storyboard stages.
- Theme-token contrast checked in all ten palette/mode combinations: main text, muted text on panels and CTA text exceed 4.5:1 (lowest measured CTA pair 5.87:1).
- No browser console errors in the tested production-preview flow.
- Reduced-motion/no-JavaScript behavior reviewed in source. OS preference emulation was not available in the browser tool; those modes still need a manual device/accessibility pass.
- No physical Android install/update was performed; the actual downloaded APK’s hash and embedded manifest were verified instead.
- Final screenshots are saved in ignored `artifacts/`.

## Remaining limits

Website release 1.0.1 is promoted to main independently of the mobile changes on dev. GitHub outages/rate limits can prevent a live freshness check; users are told when last-known information is shown. Static release-detail URLs, RSS and SEO need deployment to gain a new version, while the timeline/download panels can refresh in the browser.

Username sharing, sync service and device transfer are a planned product direction, not an implemented backend. Local backup restore does not promise future username credential recovery. Current local storage and exported backups are not represented as encrypted.

The old-download historical root cause remains unproven; current v2.0.1 bytes are verified. Future CI gates have unit coverage but need their first real, authorized signed release run. Responsive checks are desktop browser emulations, not physical mobile Safari/Chrome or a full screen-reader certification.


## Follow-up: automatic stories and independent releases

Mira now has a distinct long hairstyle, hair clip, earrings and rose dress; Dev has a short quiff, teal jacket, trousers and sneakers. Mira also appears in the backup story. Both stories loop at 3.5 seconds per scene with no play/replay/next controls; transcripts and reduced-motion behavior remain. Username sharing is explicitly upcoming.

The app/site version manifests and dev-to-main publication policy are documented in `../PIPELINE.md`. The branches started at the same existing commit; the website is promoted independently of unreleased mobile changes. Local checks: 35 site tests, seven version-gate tests, two APK verifier tests; Astro check and production build pass. The updated character scenes and automatic progression were inspected in the browser, including a mobile backup layout. Workflow YAML parses successfully; signing, publication and deployment were not executed. A local debug APK build was attempted but this machine has no Android SDK, so the new debug application ID still needs an Android build on CI.
