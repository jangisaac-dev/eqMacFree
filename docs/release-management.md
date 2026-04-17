# eqMacFree Release Management

## Versioning

- Product version: semantic version in `MARKETING_VERSION`
- Build number: monotonic integer in `CURRENT_PROJECT_VERSION`
- Public tag prefix: `eqmacfree-v`

Example:

- Product version: `1.0.1`
- Build number: `10001`
- Git tag: `eqmacfree-v1.0.1`

## Why tags are namespaced

The repository already contains historical upstream tags such as `v1.0.0`.
eqMacFree releases use `eqmacfree-v*` tags so the public fork can start at `1.0.0`
without colliding with upstream tag history.

## Update strategy

### Phase 1: Sparkle-ready appcast updates

- Sparkle points to a stable appcast hosted from `docs/appcast/stable.xml`
- Release archives are zipped app bundles built from the Release configuration
- The archive is signed with the Sparkle EdDSA private key stored in Keychain
- The appcast includes a real `<enclosure>` entry for Sparkle downloads
- GitHub Releases hosts the downloadable archive

### Phase 2: Fully trusted automatic updates

- Add notarized release archives (`zip` or `dmg`)
- Add notarization submission and stapling to the release pipeline
- Publish appcast updates as part of the tagged release flow

## Release preparation

Prepare versions:

```bash
npm run release:prepare -- --version 1.0.1 --build 10001 --channel stable
```

Build distribution artifacts:

```bash
npm run release:build
```

This synchronizes and builds:

- root `package.json`
- app Xcode marketing/build versions
- driver Xcode marketing/build versions
- target appcast feed
- release zip archive
- signed Sparkle enclosure metadata

Commit and tag:

```bash
git add package.json ui/package.json native/app/Assets/Embedded/ui.zip native/app/Supporting\ Files/Info.plist native/app/eqMac.xcodeproj/project.pbxproj native/driver/Driver.xcodeproj/project.pbxproj docs/appcast/stable.xml docs/appcast/beta.xml scripts/release/build-distribution.sh scripts/release/publish-release.sh
git commit -m "release: ship 1.0.1"
git tag -a eqmacfree-v1.0.1 -m "eqMacFree 1.0.1"
```

Publish the GitHub Release asset:

```bash
npm run release:publish
```

Keep `docs/appcast/stable.xml` and `docs/appcast/beta.xml` on the default branch aligned with the latest public release.

## Final clean-history cutover

When the product reaches the point where only the newest public version should remain:

```bash
VERSION=1.2.0 BUILD_NUMBER=10200 bash scripts/release/finalize-clean-cutover.sh
```

What this does:

- creates a local backup branch before any destructive change
- creates a new orphan release branch containing only the current tree snapshot
- tags that snapshot with the requested `eqmacfree-v*` tag
- deletes older GitHub releases
- deletes older remote tags
- force-updates remote `main` so only the final snapshot history remains

This should be run only after the final feature batch is complete and verified.
