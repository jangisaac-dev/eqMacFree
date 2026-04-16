# eqMacFree Baseline Feature Issues

**Date:** 2026-04-17

## Launch blocker

- Resolved for the current worktree. The app now builds and launches through `./script/build_and_run.sh --verify`.
- Root-cause fixes applied:
  - replaced dead or fragile pod sources with public or vendored sources
  - removed `SwiftHTTP` by replacing it with `URLSession`
  - removed `Sentry` crash-reporting dependency from the baseline build path
  - vendored and patched `AMCoreAudio` for current Xcode/macOS SDK compatibility
  - updated project deployment target to macOS 10.13

## System audio processing

- None recorded yet.

## Volume booster

- None recorded yet.

## HDMI volume support

- None recorded yet.

## Volume balance control

- None recorded yet.

## Basic EQ

- None recorded yet.

## Advanced EQ

- None recorded yet.
