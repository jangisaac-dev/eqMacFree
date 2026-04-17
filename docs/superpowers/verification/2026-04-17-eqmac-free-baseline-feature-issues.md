# eqMacFree Baseline Feature Issues

**Date:** 2026-04-17

## Launch blocker

- App build is restored, but baseline verification is still blocked by HAL driver installation.
- Root-cause fixes applied:
  - replaced dead or fragile pod sources with public or vendored sources
  - removed `SwiftHTTP` by replacing it with `URLSession`
  - removed `Sentry` crash-reporting dependency from the baseline build path
  - vendored and patched `AMCoreAudio` for current Xcode/macOS SDK compatibility
  - updated project deployment target to macOS 10.13
  - restored standalone `eqMacFree.driver` build by:
    - aligning the driver deployment target with the shared package
    - fixing the generated Swift bridge header import name
    - removing the stale Xcode-side auto-install script that hard-failed the build
- Current runtime blocker:
  - `./script/build_and_run.sh --verify` now fails fast because the driver installation step needs either passwordless `sudo` or an executable `$HOME/askpass.sh`.
  - The local environment currently has neither:
    - `sudo -n true` fails with `a password is required`
    - `~/askpass.sh` is absent
- Evidence collected:
  - standalone driver build now succeeds:
    - `xcodebuild -project native/driver/Driver.xcodeproj -scheme 'Driver - Debug' -configuration Debug -derivedDataPath build-driver build`
  - run script currently stops at:
    - `Driver build succeeded, but installation requires passwordless sudo or $HOME/askpass.sh.`
  - legacy installed driver remains present at `/Library/Audio/Plug-Ins/HAL/eqMac.driver`, but it does not expose the expected `EQMDevice` to the current app path.

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
