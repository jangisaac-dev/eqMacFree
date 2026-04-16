# eqMacFree Phase 1 Feature Inventory

This inventory captures the public snapshot as launched under `eqMacFree`.

## Available now

These capabilities are present in the public snapshot and are treated as usable launch features for Phase 1:

- System audio processing
- Volume booster
- HDMI volume support
- Volume balance control
- Basic EQ
- Advanced EQ

## Lock candidates

These are launch-surface items that may still imply unavailable functionality, roadmap work, or future unlockable concepts. They should stay clearly marked as unavailable or planned until reimplemented.

- Shared UI lock badge and related unavailable-feature presentation
- Settings or onboarding copy that refers to preview, roadmap, or future capabilities
- Any remaining user-facing references to unavailable advanced audio workflows

## Missing reimplementation

These capabilities were described historically around eqMac but are not materially implemented in the public snapshot and should be treated as new engineering work:

- Expert EQ
- Spectrum analyzer
- AudioUnit hosting
- Spatial audio
- Volume mixer

## Phase 1 launch boundary

Phase 1 intentionally stops at:

- repo/app rebrand to `eqMacFree`
- native and UI identity cleanup
- legacy hosted-service neutralization
- feature inventory and backlog seeding

Phase 1 does **not** include rebuilding missing lock features.

## Verification notes

The current launch boundary assumes:

- `eqMacFree` is an independent public app derived from the last open snapshot
- legacy eqMac hosted UI, Sparkle feeds, analytics, and support routing are not trusted as active production infrastructure for this launch
- future missing features will be implemented one by one as explicit roadmap work
