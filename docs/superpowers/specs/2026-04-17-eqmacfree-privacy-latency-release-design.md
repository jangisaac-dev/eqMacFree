# eqMacFree Privacy, Latency, and Release Design

## Goal

Make the public eqMacFree build truthful about data collection, reduce obvious interaction latency in the audio pipeline, and establish a fork-owned `1.0.0` release/update path.

## Current state

- Startup privacy UI still offers telemetry and crash-report options.
- Telemetry still has a live Google Analytics injection path in the Angular UI.
- Crash-report storage exists, but active reporting infrastructure is disabled in the native app.
- Re-enabling the app waits on a fixed 1000 ms delay before recreating the audio pipeline.
- Equalizer Basic/Advanced switching waits in the UI for 500 ms and also rebuilds audio through a heavy stop-and-setup path.
- The app includes Sparkle, but runtime feeds are disabled and the current `SUFeedURL` points at a GitHub releases HTML page rather than an appcast feed.
- The repo already contains historical upstream tags including `v1.0.0`.

## Design decisions

### Privacy

- Treat telemetry and crash reporting as unavailable in the current public build.
- Remove functional telemetry delivery by making the analytics service a no-op behind a constant gate.
- Skip the startup privacy prompt entirely when no collection services are active.
- Hide or disable privacy controls in settings unless a real backend is configured.

### Latency

- Replace the fixed 1000 ms re-enable wait with a short polling loop that completes as soon as the virtual output device becomes current, while keeping the old timeout as a fallback ceiling.
- Replace equalizer type switching from full passthrough teardown to local pipeline rebuild where possible.
- Remove the UI-side fixed 500 ms wait for equalizer type switching and switch the view optimistically.

### Releases and updates

- Set the public fork product version to `1.0.0`.
- Use `CURRENT_PROJECT_VERSION = 10000` as the first public fork build number.
- Use namespaced Git tags: `eqmacfree-v1.0.0`, `eqmacfree-v1.0.1`, etc.
- Enable a conservative Phase 1 Sparkle flow using a repository-hosted informational appcast that points users to GitHub Releases.
- Defer Phase 2 fully automatic updates until notarized archives and Sparkle archive signing are available.

## Risks

- Audio pipeline rebuild without full teardown must not leak listeners or leave stale engines behind.
- Informational Sparkle feeds provide update discovery, not fully automatic installation.
- Driver notarization remains a separate external blocker for fully trusted distribution.
