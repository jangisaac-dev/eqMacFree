# eqMacFree Release Management

## Versioning

- Product version: semantic version in `MARKETING_VERSION`
- Build number: monotonic integer in `CURRENT_PROJECT_VERSION`
- Public tag prefix: `eqmacfree-v`

Example:

- Product version: `1.0.0`
- Build number: `10000`
- Git tag: `eqmacfree-v1.0.0`

## Why tags are namespaced

The repository already contains historical upstream tags such as `v1.0.0`.
eqMacFree releases use `eqmacfree-v*` tags so the public fork can start at `1.0.0`
without colliding with upstream tag history.

## Update strategy

### Phase 1: Informational updates

- Sparkle points to a stable appcast hosted from `docs/appcast/stable.xml`
- The appcast advertises the latest GitHub Release
- Users are directed to GitHub Releases to download the newer build
- This avoids depending on signed enclosure artifacts before distribution is stabilized

### Phase 2: Fully automatic updates

- Add notarized release archives (`zip` or `dmg`)
- Sign the archive with the Sparkle EdDSA private key matching `SUPublicEDKey`
- Add `<enclosure>` items to the appcast
- Publish appcast updates as part of the tagged release flow

## Release preparation

Run:

```bash
npm run release:prepare -- --version 1.0.0 --build 10000 --channel stable
```

This synchronizes:

- root `package.json`
- app Xcode marketing/build versions
- driver Xcode marketing/build versions
- target appcast feed

After that:

```bash
git add package.json native/app/eqMac.xcodeproj/project.pbxproj native/driver/Driver.xcodeproj/project.pbxproj docs/appcast/stable.xml
git commit -m "release: prepare 1.0.0"
git tag -a eqmacfree-v1.0.0 -m "eqMacFree 1.0.0"
```

Publish a GitHub Release for the tag, then keep `docs/appcast/stable.xml` on the default branch aligned with the latest public release.
