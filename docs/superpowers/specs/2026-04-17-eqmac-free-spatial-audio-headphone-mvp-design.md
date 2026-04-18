# eqMacFree Spatial Audio Headphone MVP Design Spec

**Date:** 2026-04-17  
**Status:** Approved for planning  
**Source repo:** `/Volumes/ssd/opencode_workspace/eqMac`  
**Project type:** Missing-feature reimplementation and public MVP delivery

## 1. Summary

This spec defines the first free public reimplementation slice for **Spatial Audio** in `eqMacFree`.

The goal of this slice is not to unlock hidden Pro code.
The goal is to build and ship a new public Spatial Audio feature that delivers similar user value for free, within the real constraints of the current public repo.

The first slice should produce:

- a real audible headphone-oriented Spatial Audio mode in the app-layer output graph
- a persisted native on/off setting for the behavior
- a simple Settings-based control surface for enabling the feature
- clear experimental/product wording that does not overclaim full system-wide or multichannel spatial support

This slice exists because `Spatial audio` is already documented across the public repo as a missing reimplementation, but the current codebase does not yet expose any real free equivalent.

## 2. Why this feature is next

The public roadmap already defines Spatial Audio as missing reimplementation work.

Relevant repo references:

- `README.md` lists `Spatial audio` under `### Missing reimplementation`
- `docs/roadmap/phase-1-feature-inventory.md` lists `Spatial audio` under `## Missing reimplementation`
- `docs/roadmap/lock-feature-backlog.md` defines the backlog item as:

> Spatial audio  
> - Research feasibility against the current native audio pipeline  
> - Define a minimal public implementation before UI work starts

That backlog wording matters. It does not describe a hidden feature waiting to be turned on. It describes a feature that still needs a new public implementation.

The user’s explicit product direction is also clear:

- the purpose is to build functionality similar to the Pro version
- the result should be available for free in `eqMacFree`
- the work must remain honest about the current public repo’s real capabilities

## 3. Product intent

### 3.1 What this feature is

This first Spatial Audio slice is:

- a free public reimplementation of pro-like Spatial Audio value
- the first working audible version of Spatial Audio in `eqMacFree`
- an app-layer feature built on the existing output pipeline
- a headphone-oriented MVP designed to deliver real value before broader DSP expansion

### 3.2 What this feature is not

This feature is not:

- a hidden Pro unlock
- a fake badge or roadmap-only surface
- a claim of full multichannel speaker spatialization
- a claim of device-wide object-based spatial audio parity
- a claim that the driver now supports non-stereo output formats

## 4. Problem statement

`eqMacFree` already documents Spatial Audio as a missing reimplementation, but the public app currently offers no real free equivalent. Users therefore have roadmap intent without usable functionality.

The current public repo has enough audio infrastructure to build a meaningful first slice, but it also has hard constraints:

1. **The current pipeline is stereo-centered**  
   The driver/device constants, stream handling, engine buffer, and output format are all currently centered on 2-channel audio.

2. **The app already owns a real audible output graph**  
   `native/app/Source/Audio/Outputs/Output.swift` builds the playback path and is the most credible seam for adding a new app-layer audible effect.

3. **AVFoundation offers a real spatial renderer with limits**  
   `AVAudioEnvironmentNode` can provide an audible binaural/spatialized effect on macOS, but it spatializes mono inputs rather than arbitrary stereo program material.

4. **Settings and UI plumbing already exist**  
   The repo already has persisted native settings, a Settings screen, and optional UI feature visibility flags.

The missing piece is a narrowly scoped public implementation that produces a real first Spatial Audio behavior without pretending the repo already has full multichannel or driver-level spatial support.

## 5. Repo-grounded discoveries

### 5.1 Spatial Audio is documented as future reimplementation work

Relevant files:

- `README.md`
- `docs/roadmap/phase-1-feature-inventory.md`
- `docs/roadmap/lock-feature-backlog.md`
- `docs/superpowers/specs/2026-04-16-eqmac-free-design.md`

Observed facts:

- Spatial Audio is consistently framed as `Missing reimplementation`
- no roadmap doc describes it as already implemented or merely hidden
- no current Help / Lock UX surface exists for Spatial Audio the way `Volume Mixer` now does

### 5.2 The current public audio path is still stereo-centered

Relevant files:

- `native/driver/Source/Constants.swift`
- `native/driver/Source/EQMDevice.swift`
- `native/driver/Source/EQMStream.swift`
- `native/app/Source/Audio/Engine.swift`
- `native/app/Source/Audio/Outputs/Output.swift`

Observed facts:

- `kChannelCount` is defined as `2`
- the driver reports stereo preferred channels/layout
- stream comments state the current device supports 2-channel 32-bit float audio
- `Engine.swift` builds a 2-channel `CircularBuffer<Float>`
- `Output.swift` constructs a stereo `AVAudioFormat`

Important constraint:

- a truthful first free reimplementation cannot claim full multichannel spatial output because the public repo is not there yet

### 5.3 The best runtime insertion seam is the output graph

Relevant files:

- `native/app/Source/Audio/Outputs/Output.swift`
- `native/app/Source/Application.swift`
- `native/app/Source/Audio/Volume/Volume.swift`

Observed facts:

- `Output.swift` owns the audible playback graph:
  - `player`
  - `varispeed`
  - `volume.mixer`
  - `mainMixerNode`
- the current chain is:
  - `player -> varispeed -> volume.mixer -> mainMixerNode`
- `Application.createAudioPipeline()` recreates `Output(device:)` when the pipeline is rebuilt
- `Volume.swift` already shows the repo pattern for a runtime audio behavior object that reacts to app state

This makes `Output.swift` the correct first place to insert Spatial Audio processing.

### 5.4 Settings and Settings UI already support a small MVP surface

Relevant files:

- `native/app/Source/Settings/SettingsState.swift`
- `native/app/Source/Settings/Settings.swift`
- `native/app/Source/Settings/SettingsDataBus.swift`
- `ui/src/app/sections/settings/settings.service.ts`
- `ui/src/app/sections/settings/settings.component.ts`
- `ui/src/app/services/ui.service.ts`
- `native/app/Source/UI/UIDataBus.swift`

Observed facts:

- persisted native booleans are already stored in `SettingsState`
- `SettingsDataBus` already exposes `GET/POST` routes for boolean settings
- `SettingsService` already wraps those routes in Angular
- the Settings screen is already option-driven and can add a new checkbox without a structural rewrite
- `UIService` already maintains UI-only feature visibility flags if a later section needs to be revealed

### 5.5 AVFoundation feasibility is real but bounded

External feasibility research and repo fit suggest:

- `AVAudioEnvironmentNode` is the most credible built-in path for a first audible Spatial Audio effect on macOS
- the node can produce a binaural/spatialized headphone effect
- but the node expects a mono source for actual spatialization behavior

That means the first free MVP should be a **headphone-oriented experimental spatial renderer**, not a promise that all existing stereo content is now fully object-spatialized.

## 6. Product direction

The approved product direction for this slice is:

- build a free feature that gives users real Spatial Audio-like value
- ship the first working version inside the current public architecture
- prefer audible usefulness over fake completeness
- keep the feature framed as experimental and headphone-oriented until the repo supports broader claims

That means the first version should optimize for:

- real audible change
- clear enable/disable control
- low-risk integration with the existing output graph
- room to grow into richer controls later

## 7. Proposed architecture

### 7.1 Core concept

The first free Spatial Audio implementation should be a **Headphone Spatial Audio MVP** that inserts a spatialized rendering path into the existing app-layer output graph.

Recommended conceptual path:

1. a persisted `spatialAudioEnabled` behavior toggle lives in native settings
2. `Output.swift` constructs an additional spatial processing path when the feature is enabled
3. the path feeds a mono source into `AVAudioEnvironmentNode`
4. the environment node outputs a binaural/spatialized headphone-oriented result into the normal output chain
5. the Settings screen exposes a simple on/off control and clearly labels it as experimental headphone-focused behavior

### 7.2 Proposed native state contract

Recommended settings shape:

```swift
struct SettingsState: State {
  var iconMode: IconMode = .both
  @DefaultFalse var doCollectCrashReports = false
  @DefaultFalse var doAutoCheckUpdates = false
  @DefaultFalse var doOTAUpdates = false
  @DefaultFalse var doBetaUpdates = false
  @DefaultFalse var spatialAudioEnabled = false
}
```

Recommended action surface:

```swift
enum SettingsAction: Action {
  case setIconMode(IconMode)
  case setDoCollectCrashReports(Bool)
  case setDoAutoCheckUpdates(Bool)
  case setDoOTAUpdates(Bool)
  case setDoBetaUpdates(Bool)
  case setSpatialAudioEnabled(Bool)
}
```

Recommended native settings route:

- `GET /settings/spatial-audio-enabled`
- `POST /settings/spatial-audio-enabled`

### 7.3 Proposed UI and settings contract

Recommended Angular/native service surface:

```ts
getSpatialAudioEnabled(): Promise<boolean>
setSpatialAudioEnabled({ spatialAudioEnabled }: { spatialAudioEnabled: boolean })
getSpatialAudioPreset(): Promise<SpatialAudioPreset>
setSpatialAudioPreset({ spatialAudioPreset }: { spatialAudioPreset: SpatialAudioPreset })
```

Recommended persisted native state surface:

```swift
@DefaultFalse var spatialAudioEnabled = false
var spatialAudioPreset: SpatialAudioPreset = .music
```

The feature should be exposed in two places with one shared source of truth:

- a new main-surface `Spatial Audio` card inserted directly below `Volume/Balance`
- the existing Settings screen, kept as a secondary experimental mirror of the same state

The main-surface card is the primary interaction model for the first usable release because it makes the feature immediately testable without forcing the user into Settings.

Recommended main-surface behavior:

- match the existing eqMac section language instead of introducing a visually separate design system
- include an `On/Off` toggle in the card header
- include a collapse/expand affordance using the same general interaction pattern users already know from Equalizer visibility
- show the currently selected preset in the collapsed summary state
- when expanded, show 3 user-facing presets with direct one-click switching

Recommended preset naming for the first public testable version:

- `Cinema`
- `Music`
- `Voice`

These names are intentionally user-oriented rather than technical. The goal of the first public test slice is fast subjective listening feedback, not exposing DSP terminology.

Recommended Settings-screen behavior:

- keep a `Spatial Audio (Headphones)` control in Settings
- describe it as experimental and headphone-oriented
- do not position Settings as the primary discovery surface
- if preset selection is also shown in Settings, label it as experimental/advanced rather than the default entry point

### 7.4 Runtime audio boundary

The first MVP should keep the driver contract unchanged.

That means:

- no driver channel-count changes
- no multichannel layout claims
- no `EQMDevice` / `EQMStream` widening for this slice

The runtime implementation boundary is instead:

- `Output.swift` owns the playback graph insertion
- `Settings.swift` reacts to state changes and triggers rebuild/update behavior if needed
- `Application.createAudioPipeline()` / `startPassthrough()` remain the existing lifecycle path

### 7.5 Headphone-oriented gating and preset behavior

The first MVP should be framed and implemented for headphone listening.

Recommended behavior:

- the setting can be enabled globally
- the selected preset should persist across launches
- presets should change the audible character of the spatial path rather than only relabeling the same processing
- runtime can choose to bypass or degrade gracefully on obviously unsupported output situations
- UI/help text should avoid promising speaker virtualization parity

The first MVP does not need a perfect device classifier, but it should stay truthful in wording and behavior.

Recommended preset intent:

- `Cinema`: widest and most dramatic presentation
- `Music`: balanced default presentation for general listening
- `Voice`: tighter, more centered presentation with lower spatial exaggeration

## 8. Scope

### 8.1 In scope

- persisted native `spatialAudioEnabled` setting
- persisted native `spatialAudioPreset` state
- matching settings routes and Angular service methods for both values
- a new main-surface `Spatial Audio` card below `Volume/Balance`
- collapse/expand behavior for that card using existing app interaction patterns
- 3 direct user-facing presets: `Cinema`, `Music`, `Voice`
- Settings-screen controls that mirror the same state with experimental wording
- app-layer audible spatial processing inserted into `Output.swift`
- experimental headphone-oriented wording
- rebuild/runtime wiring needed so the output graph honors the setting

### 8.2 Out of scope

- multichannel driver/device support
- speaker-oriented spatial virtualization claims
- head tracking
- advanced 3D scene controls
- per-app spatial positioning
- hidden Pro compatibility shims

## 9. Acceptance criteria

This slice is complete when all of the following are true:

1. The repo contains a persisted native setting for enabling/disabling Spatial Audio.
2. The repo contains a persisted native preset value for Spatial Audio with 3 user-facing options.
3. The main app surface exposes a visible `Spatial Audio` card below `Volume/Balance` so the feature is easy to test immediately.
4. That card supports `On/Off`, collapse/expand, and direct preset selection.
5. The Settings UI mirrors the same state but is framed as an experimental/advanced surface rather than the main discovery path.
6. The output graph changes audible behavior when the feature is enabled, and selected presets alter the spatial rendering character.
7. The implementation uses an app-layer spatial rendering path grounded in AVFoundation rather than fake placeholder logic.
8. The wording stays truthful: free reimplementation, experimental, headphone-oriented, not full multichannel parity.
9. Existing non-Spatial-Audio routing still compiles and the app remains buildable within the repo’s available verification surfaces.

## 10. Verification strategy

Because this repo does not currently surface a ready native unit-test harness, verification must use the smallest honest seams available.

Minimum required verification for this slice:

- re-read the modified Swift and TypeScript files to confirm the behavior follows this spec
- run repo verification commands that are available after edits
- confirm git status reflects only the intended Spatial Audio changes
- confirm the settings contract is consistent across:
  - `SettingsState.swift`
  - `SettingsDataBus.swift`
  - `Settings.swift`
  - `settings.service.ts`
  - `settings.component.ts`
- confirm the new main-surface UI contract is consistent across:
  - `app.component.ts`
  - `app.component.html`
  - the new Spatial Audio section component/service files
- confirm the audio path changes live in `Output.swift` instead of pretending the driver became multichannel
- manually verify the user flow:
  - Spatial Audio card is visible on the main surface
  - toggling `On` rebuilds or refreshes the runtime path without breaking the app shell
  - switching between `Cinema`, `Music`, and `Voice` updates persisted state and remains selected after refresh/reopen
  - Settings reflects the same enabled/preset state

If a usable build/lint command can be run from the current workspace, it must be included before completion claims.

## 11. Follow-up sequencing

After this first MVP, the likely next steps are:

1. richer Spatial Audio controls and better runtime status
2. better preset tuning from real listening feedback
3. improved output/device gating
4. deeper DSP expansion only after the public repo can honestly support it

## 12. Final design decision

The first free public reimplementation of Spatial Audio in `eqMacFree` should be a **Headphone Spatial Audio MVP** centered on a new main-surface Spatial Audio card.

That is the best fit between:

- the user’s real goal: free reimplementation of Pro-like value
- the repo’s real capabilities: stereo app-layer audio graph with existing settings/UI plumbing
- the requirement to ship something truthful, audible, extensible, and immediately testable instead of a fake unlock or an overclaimed multichannel feature
