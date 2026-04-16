# eqMacFree Former Pro Reimplementation Program Design Spec

**Date:** 2026-04-17  
**Status:** Drafted from approved design discussion  
**Source repo:** `/Volumes/ssd/opencode_workspace/eqMac`  
**Project type:** Product-boundary validation and staged free reimplementation program

## 1. Summary

This spec defines the operating program for `eqMacFree` after the initial public repo cleanup work.

The program goal is:

1. verify that the current free feature set actually works
2. keep former Pro-only surfaces from implying payment or upgrade flows
3. rename locked Pro surfaces to `Lock` and mark them as planned development
4. list former Pro features as a free reimplementation backlog
5. implement and release those former Pro features one by one as free features

The first reimplementation priority is `Spatial Audio`.

## 2. Product intent

### 2.1 What this program is

This program is:

- a validation gate for the current free app
- a terminology and UX boundary policy for not-yet-implemented former Pro features
- a backlog and delivery model for rebuilding former Pro value as free features
- a staged release process that prevents new feature work from starting before the current free baseline is proven

### 2.2 What this program is not

This program is not:

- a hidden-feature unlock project
- a payment funnel rewrite
- a promise to ship every former Pro feature at once
- a license bypass effort

## 3. Current repo reality

The current repo already contains substantial groundwork for this direction:

- [`README.md`](/Volumes/ssd/opencode_workspace/eqMac/README.md) defines `Available now` vs missing reimplementation features.
- [`docs/roadmap/phase-1-feature-inventory.md`](/Volumes/ssd/opencode_workspace/eqMac/docs/roadmap/phase-1-feature-inventory.md) and [`docs/roadmap/lock-feature-backlog.md`](/Volumes/ssd/opencode_workspace/eqMac/docs/roadmap/lock-feature-backlog.md) already describe the post-launch feature boundary.
- Existing app UX work has already started replacing `Pro` wording with `Lock` in user-facing surfaces.
- Existing in-progress code adds a `spatialAudioEnabled` settings path in:
  - [`native/app/Source/Settings/SettingsState.swift`](/Volumes/ssd/opencode_workspace/eqMac/native/app/Source/Settings/SettingsState.swift)
  - [`native/app/Source/Settings/Settings.swift`](/Volumes/ssd/opencode_workspace/eqMac/native/app/Source/Settings/Settings.swift)
  - [`native/app/Source/Settings/SettingsDataBus.swift`](/Volumes/ssd/opencode_workspace/eqMac/native/app/Source/Settings/SettingsDataBus.swift)
  - [`ui/src/app/sections/settings/settings.service.ts`](/Volumes/ssd/opencode_workspace/eqMac/ui/src/app/sections/settings/settings.service.ts)
  - [`ui/src/app/sections/settings/settings.component.ts`](/Volumes/ssd/opencode_workspace/eqMac/ui/src/app/sections/settings/settings.component.ts)
  - [`native/app/Source/Audio/Outputs/Output.swift`](/Volumes/ssd/opencode_workspace/eqMac/native/app/Source/Audio/Outputs/Output.swift)

## 4. Feature model

The product-level feature model has two buckets.

### 4.1 Available now

These are the features that must already work in the current free app:

- System audio processing
- Volume booster
- HDMI volume support
- Volume balance control
- Basic EQ
- Advanced EQ

`Available now` is a runtime truth claim, not a documentation guess.

### 4.2 Former Pro Features -> Free Reimplementation Backlog

These are features that users may recognize from prior `eqMac Pro` expectations, but which are not yet available in the current public free build.

Current first-pass backlog:

- Spatial Audio
- Volume Mixer
- Spectrum Analyzer
- Expert EQ
- AudioUnit Hosting

These features are all intended to become free features over time.

## 5. Lock UX policy

`Lock` is not a product tier. It is a user-facing temporary state label.

The purpose of the label is to prevent a false payment expectation when users interact with app builds that still contain surfaces inherited from the old `Pro` model.

### 5.1 Meaning of `Lock`

When the app shows `Lock`, it must mean:

- this feature is not yet implemented in the free app
- this feature is planned or under consideration for future development
- this feature is not currently unlocked by payment, upgrade, or purchase

### 5.2 Required UX rules

- Replace visible `Pro` wording with `Lock` on unavailable former Pro surfaces.
- Add supporting copy such as `개발 예정`, `추후 제공 예정`, or a roadmap / issue handoff.
- Remove or avoid wording that implies purchase, upgrade, billing, or hidden access.
- Once a feature is implemented and verified, remove the `Lock` state and move the feature into `Available now`.

## 6. Program roadmap

The approved operating sequence is fixed.

### Phase A. App run and baseline validation

Confirm that the existing app can build, launch, and be exercised.

This phase is a hard gate. If the app does not run reliably, feature verification and new feature work stop until run/build stability is recovered.

### Phase B. Available-now feature verification

Verify the six `Available now` features in the actual app.

This phase determines whether the current free baseline is complete enough to justify any former Pro reimplementation work.

### Phase C. Lock UX boundary stabilization

Make sure all unavailable former Pro surfaces are presented as `Lock` with planned-development wording and without payment ambiguity.

### Phase D. Former Pro backlog ordering

Maintain a single queue of former Pro features to rebuild as free features.

The first feature in that queue is fixed as `Spatial Audio`.

### Phase E. Per-feature delivery loop

Each former Pro feature follows:

`spec -> plan -> implementation -> verification -> release`

After release, the feature moves from `Lock` to `Available now`.

## 7. Verification gate

`Spatial Audio` implementation does not start until the `Available now` baseline passes.

### 7.1 Scope

Verification covers:

- System audio processing
- Volume booster
- HDMI volume support
- Volume balance control
- Basic EQ
- Advanced EQ

### 7.2 Status values

Each feature gets exactly one of these statuses:

- `Pass`
- `Partial`
- `Fail`

### 7.3 Gate rule

- All six features must be `Pass` for the baseline to be considered complete.
- Any `Partial` or `Fail` blocks implementation of former Pro features.
- Architecture research and design documentation for future features may continue while the gate is unresolved.

### 7.4 Required outputs

- one verification checklist document
- one reproducible validation procedure per feature
- a tracked issue list for failures or partial results
- a final baseline decision record

## 8. Tooling and build strategy

This repository is not a pure SwiftPM app repository.

### 8.1 SwiftPM role

SwiftPM is useful for the shared native package only.

On 2026-04-17, inspection confirmed:

- no root-level `Package.swift`
- a library-only package at [`native/shared/Package.swift`](/Volumes/ssd/opencode_workspace/eqMac/native/shared/Package.swift)
- no executable SwiftPM product

The `swiftpm-macos` workflow was used to validate that package:

- command: `swift build`
- working directory: `/Volumes/ssd/opencode_workspace/eqMac/native/shared`
- result: success
- notable warnings:
  - retroactive `String: Error` / `String: LocalizedError` conformance warnings in [`StringExtensions.swift`](/Volumes/ssd/opencode_workspace/eqMac/native/shared/Source/StringExtensions.swift)
  - deprecated `assign(from:count:)` warnings in [`CircularBuffer.swift`](/Volumes/ssd/opencode_workspace/eqMac/native/shared/Source/CircularBuffer.swift)

`swift test` reported `no tests found`, which means this package currently has no SwiftPM test target.

### 8.2 App run role

Actual app build/run verification should use the macOS Xcode-oriented workflow rather than SwiftPM because the runnable product is an app/workspace, not a Swift package executable.

## 9. Spatial Audio target strategy

`Spatial Audio` is the first former Pro feature to rebuild.

### 9.1 Product target

The feature target should follow the publicly visible expectation of prior `eqMac Pro` marketing and release notes:

- a Spatial Audio feature existed as a Pro feature
- public descriptions framed it as a listening-environment or room-simulation effect
- saved state behavior mattered enough to be called out in release notes

This means the goal is not generic DSP experimentation. The goal is a free reimplementation that credibly moves toward that user expectation.

### 9.2 Phase 1: conservative release

The first release should be a conservative MVP:

- headphone-focused
- clearly labeled experimental
- simple enable/disable behavior
- persisted state
- no overclaim of multichannel or object-audio parity

This phase should prioritize a stable audible effect over UI breadth.

### 9.3 Phase 2: fuller release

The second release should move closer to the former Pro expectation:

- richer Spatial Audio UX
- named listening-environment or room-style behavior if technically justified
- clearer in-app control surface
- stronger verification and polish around switching, persistence, and user expectations

The second phase should still stay within what the public repo can honestly support.

## 10. Former Pro backlog delivery rules

- Do not open multiple former Pro implementations in parallel unless the baseline gate has already passed and the write scopes are clearly independent.
- Prefer highest user value with lowest architectural uncertainty.
- If a feature is not yet technically grounded in the public repo, run a discovery spec first.
- Keep user-facing language aligned across app UI, README, roadmap, and release notes.

## 11. Success criteria

This program is successful when all of the following are true:

1. the app can be built and launched reliably
2. all six `Available now` features are verified as `Pass`
3. unavailable former Pro surfaces no longer imply payment or purchase
4. `Lock` consistently means `planned but not yet implemented`
5. the former Pro backlog exists as an explicit free reimplementation queue
6. `Spatial Audio` becomes the first delivered feature from that queue

