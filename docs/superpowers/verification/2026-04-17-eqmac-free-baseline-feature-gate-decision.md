# eqMacFree Baseline Feature Gate Decision

**Date:** 2026-04-17

## Decision

- Current decision: `Pending`

## Gate rule

- All six `Available now` features must be `Pass`.
- Any `Partial` or `Fail` blocks former Pro feature implementation.

## Current summary

- Pass count: 0
- Partial count: 0
- Fail count: 0
- Not Run count: 6
- Verification blocked by:
  - driver install privilege requirement before runtime audio-path validation can begin

## Next action

- Complete one successful installation of `build-driver/Build/Products/Debug/eqMacFree.driver` into `/Library/Audio/Plug-Ins/HAL/eqMacFree.driver`, restart `coreaudiod`, then resume feature-by-feature baseline verification before starting `Spatial Audio` implementation.
