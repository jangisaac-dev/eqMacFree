# eqMacFree Baseline Feature Issues

**Date:** 2026-04-17

## Launch blocker

- `./script/build_and_run.sh --verify` failed before app launch because the workspace expects CocoaPods-generated xcconfig files under `native/Pods/Target Support Files/Pods-eqMac/`, but `native/Pods` was absent in the fresh worktree.
- Running `pod install` in `native/` also failed because the Podfile references `https://github.com/bitgapp/AMCoreAudio.git` at commit `b312d1509ef863dea3ca56cfa3f57451de4ff721`, and that repository is no longer publicly accessible.

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
