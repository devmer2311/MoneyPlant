# Independent app and website releases

## Branches and version ownership

Develop on `dev`. Update the relevant version manifest **on dev**, alongside the completed changes and release notes. Review its development artifact, then merge a pull request from `dev` into `main`. Main uses exactly the reviewed versions; CI never edits files, increments versions or commits code.

| Event | App manifest changed | Site manifest changed |
| --- | --- | --- |
| Push to dev | Validate and build debug APK artifact | Validate and build static site artifact |
| Pull request into dev or main | Validate and build debug APK artifact | Validate and build static site artifact |
| Push/merge to main | Validate, sign, verify and publish Android release | Validate and deploy Cloudflare production site |
| No manifest value change | No app build or release | No site build or deployment |

`versions/app.yaml` and `versions/site.yaml` are independent. Changing both builds both. Editing only comments does not build. General pull-request CI runs validation without producing APK or web release builds. Ordinary source pushes without a version change do not publish anything.

Prepare the version bump with the final release candidate. If you change code afterward, bump again to produce a new development artifact. Keep manifests in the same PR as their intended source changes. Manual dispatch compares against the previous commit; use **Re-run jobs** on the original event to retry a failed version build.

## App release

1. Increase `version` and `build` in `versions/app.yaml`. Use stable MAJOR.MINOR.PATCH and a strictly increasing Android build number.
2. From the repository root run `python tool/component_version.py app --sync-pubspec`. This updates the local pubspec only; it never commits.
3. Add matching human-written notes under `vX.Y.Z` in `site/src/data/changelog.json`. Both development and production app builds require these notes.
4. Push the prepared changes to dev when ready. Download the APK from the **App version pipeline** run's artifact. Artifacts are retained for 14 days.
5. Test the development APK, then merge dev into main. Main builds with the production key and verifies the embedded package ID, versionName and versionCode using Android SDK aapt.
6. CI creates a draft GitHub release at the exact main commit, uploads the versioned universal APK, compatibility alias and SHA-256 file, downloads them again, verifies the bytes, then publishes.

Development APKs use a debug key and the `.dev` application ID suffix so they can coexist with the production installation. Their data is separate. They are Actions artifacts, never public GitHub Releases. A fresh runner can generate a different debug key; reinstall the development app if Android reports a signature mismatch.

The initial manifest mirrors the existing app version, 2.0.1+4. An already tagged main version is skipped; adopting these files does not republish it. For a future patch, an example is 2.0.2+5, with matching notes. Do not update the example version until that release is intended.

## Website release

1. Increase `version` in `versions/site.yaml` on dev.
2. The **Site version pipeline** tests, type-checks and builds the site. Its dev/PR artifact can be downloaded and served locally; it does not deploy.
3. Merge into main to deploy the verified artifact to the existing `moneyplantbydev` Cloudflare Pages project.
4. A successful deployment records a `site-vX.Y.Z` tag at the built commit. This is a Git tag, not an Android GitHub release. `/site-version.json` records the deployed version and commit.

The first deployed site manifest is 1.0.1. Site versions do not have to match app versions. Publishing an APK does not automatically rebuild the site. Browser download panels and the release timeline discover new public APK releases; bump the site version when static detail pages, RSS and SEO need refreshing. If releasing both together, release the app first, then bump/merge the site version so its static build includes the newly published APK.

## Repository configuration

Required repository Actions secrets:

- App: `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`. Preserve the existing production signing key.
- Website: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`. The token needs deployment access to the existing Pages project.
- GitHub's automatic `GITHUB_TOKEN` supplies scoped repository access. Only main publication/deployment jobs receive contents-write permission.

Keep GitHub Actions as the production deployment owner. If Cloudflare's independent Git auto-deployment is enabled, disable that automatic deployment so it cannot bypass the manifest gate.

Recommended main protection: require a reviewed pull request and the always-running **Validate / checks** status. Do not require path-filtered app/site workflows globally: they are intentionally absent for unrelated PRs. Branch protection was not changed by this implementation.

## Recovery and verification

A failed app validation never publishes. A failed upload verification leaves a draft for deliberate recovery. Do not move a published tag or replace public release bytes. Investigate any retained draft before retrying; remove only a confirmed failed unpublished draft if necessary, or prepare a fresh version.

Existing release/deployment tags are never overwritten. A main version below a recorded version fails. App semantic version and build must both increase; site semantic version must increase. If Cloudflare deploy succeeds but recording its tag fails, retry that deploy job after checking the deployment; redeploying the same artifact is safe.

After publication, verify the website's versioned download URL, checksum and APK metadata, and test upgrade/restore on an Android device. After a site deployment check `/site-version.json` and mobile/desktop layouts.

Website and shared pipeline changes are promoted to main independently of the unreleased mobile storage changes on dev. The mobile app remains at 2.0.1+4 until an app release is explicitly prepared.
