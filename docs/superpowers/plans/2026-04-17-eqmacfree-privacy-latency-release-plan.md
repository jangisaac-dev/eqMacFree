# eqMacFree Privacy, Latency, and Release Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove misleading data-collection behavior, reduce obvious UI/audio restart lag, and wire a fork-owned `1.0.0` release/update path.

**Architecture:** Keep privacy changes declarative through shared constants, reduce latency by replacing fixed waits and heavy restart paths with narrower rebuilds, and add a conservative informational Sparkle appcast backed by GitHub Releases and namespaced tags.

**Tech Stack:** Angular, TypeScript, Swift/AppKit, Sparkle 1.x, Xcode project build settings, raw GitHub-hosted XML appcast.

---

### Task 1: Privacy truthfulness

**Files:**
- Modify: `ui/src/app/services/constants.service.ts`
- Modify: `ui/src/app/services/analytics.service.ts`
- Modify: `ui/src/app/app.component.ts`
- Modify: `ui/src/app/sections/settings/settings.component.ts`

- [ ] Gate telemetry and crash-report UI from shared constants.
- [ ] Make analytics initialization a no-op unless telemetry is explicitly enabled in code.
- [ ] Skip the startup privacy prompt when no live collection backends exist.
- [ ] Verify the Angular files still lint cleanly.

### Task 2: Interaction latency

**Files:**
- Modify: `native/app/Source/Application.swift`
- Modify: `ui/src/app/sections/effects/equalizers/equalizers.component.ts`

- [ ] Replace the fixed 1000 ms `startPassthrough` delay with adaptive waiting and timeout fallback.
- [ ] Replace equalizer type-change full restart with a narrower audio pipeline rebuild.
- [ ] Remove the fixed 500 ms frontend wait on equalizer type changes.
- [ ] Verify the macOS app still builds and launches.

### Task 3: Release and update plumbing

**Files:**
- Modify: `native/app/Source/Constants.swift`
- Modify: `native/app/Source/Application.swift`
- Modify: `native/app/Source/ApplicationDataBus.swift`
- Modify: `native/app/Supporting Files/Info.plist`
- Modify: `native/app/eqMac.xcodeproj/project.pbxproj`
- Modify: `native/driver/Driver.xcodeproj/project.pbxproj`
- Modify: `package.json`
- Create: `scripts/release/prepare-release.mjs`
- Create: `docs/appcast/stable.xml`
- Create: `docs/appcast/beta.xml`
- Create: `docs/release-management.md`

- [ ] Set product version to `1.0.0` and build number to `10000`.
- [ ] Expose user-visible app version as short version string and keep build number separate.
- [ ] Point Sparkle at a real appcast URL.
- [ ] Add a reusable release-preparation script that syncs versions and appcast contents.
- [ ] Document the namespaced tag strategy and the Phase 1 vs Phase 2 update path.

### Task 4: Verification and commit

**Files:**
- Modify: none

- [ ] Run targeted Angular lint on changed UI files.
- [ ] Run `./script/build_and_run.sh --verify`.
- [ ] Confirm the remaining blocker is still driver notarization rather than app startup.
- [ ] Commit the change set with a release/privacy/latency summary.
