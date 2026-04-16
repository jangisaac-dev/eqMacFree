# eqMacFree

Independent macOS audio app rebuilt from the public eqMac snapshot.

## Project status

eqMacFree is the public launch base for an independent continuation of the last open eqMac snapshot.

- Phase 1 focuses on rebranding the public repo and app surfaces for an independent launch.
- This project does **not** bypass Pro licensing or private-repo functionality.
- Former Pro-only capabilities that are absent from the public snapshot are treated as future reimplementation work.

## Feature inventory

### Available now
- System audio processing
- Volume booster
- HDMI volume support
- Volume balance control
- Basic EQ
- Advanced EQ

### Lock candidates
- UI and documentation surfaces that still imply unavailable premium functionality
- User-facing copy that still points at the old eqMac product funnel

### Missing reimplementation
- Expert EQ
- Spectrum analyzer
- AudioUnit hosting
- Spatial audio
- Volume mixer

Detailed tracking lives in:

- [`docs/roadmap/phase-1-feature-inventory.md`](docs/roadmap/phase-1-feature-inventory.md)
- [`docs/roadmap/lock-feature-backlog.md`](docs/roadmap/lock-feature-backlog.md)

## Community and support

- Use [GitHub Issues](https://github.com/jangisaac-dev/eqMacFree/issues) for bug reports and tracked work.
- Use GitHub Discussions or pull requests for collaboration once the public repo is live.
- eqMacFree should be understood as an independent continuation of the public snapshot, not the private eqMac Pro line.

## Guardrails

- Locked historical capabilities should point users to roadmap/issues tracking rather than upgrade or purchase flows.
- Run `yarn audit:boundary` before merging launch-surface changes.
- See [`docs/guardrails/feature-capability-audit.md`](docs/guardrails/feature-capability-audit.md) for the release checklist and audit rule intent.

## Technology

eqMacFree currently retains the public snapshot architecture:

- [`native/app`](native/app) - Native macOS application layer for audio processing, lifecycle, and desktop integration.
- [`ui`](ui) - Angular and TypeScript user interface currently loaded by the native app.
- [`native/driver`](native/driver) - CoreAudio loopback/passthrough driver used by the app audio pipeline.

## Credits and attribution

- Public snapshot originally created by [@nodeful](https://github.com/nodeful) as eqMac.
- [@titanicbobo](https://github.com/titanicbobo) contributed the Big Sur icon design work present in the public assets.
- [Max Heim](https://github.com/0bmxa) contributed foundational research around Swift-based audio server plug-in driver work through [Pancake](https://github.com/0bmxa/Pancake).
