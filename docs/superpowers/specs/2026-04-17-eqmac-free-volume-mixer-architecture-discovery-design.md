# eqMacFree Volume Mixer Architecture Discovery Design Spec

**Date:** 2026-04-17  
**Status:** Approved for planning  
**Source repo:** `/Volumes/ssd/opencode_workspace/eqMac`  
**Project type:** Missing-feature architecture discovery and public implementation-prep

## 1. Summary

This spec defines the next `eqMacFree` follow-up feature slice for **Volume Mixer**.

The goal of this slice is not to ship a full per-app mixer yet.
The goal is to convert `Volume Mixer` from a roadmap placeholder into an implementation-ready public subsystem definition that is grounded in the current public codebase.

The first slice should produce:

- a concrete architecture map of the existing native and UI surfaces that a mixer would depend on
- a proposed public data model for app/client-level volume entries
- a proposed native/UI contract that fits the existing data-bus and Angular service patterns
- an explicit verification strategy for future implementation work

This slice exists because `eqMacFree` already exposes `Volume Mixer` as a locked future feature in the Help flow, but the public repo does not yet define the real client-tracking, routing, and UI boundaries needed to implement it safely.

## 2. Why this feature is next

The repo already completed the two Priority 1 backlog items:

- Lock-state UX cleanup
- Feature capability audit automation

The next backlog item in `docs/roadmap/lock-feature-backlog.md` is:

> Volume mixer  
> - Investigate per-app volume architecture in the public codebase  
> - Define data model, native integration points, and UI surface  
> - Deliver as an isolated feature spec and implementation plan

That backlog wording is important. It explicitly calls for **discovery and definition first**, not speculative implementation.

This is the right next move because the public repo already contains enough evidence to justify a real mixer architecture study:

- the native driver tracks individual clients via `EQMClient` and `EQMClients`
- the driver already passes a `client` object into device I/O
- the app already exposes volume routes through `EngineDataBus` and `VolumeDataBus`
- the UI already has a real `/volume` surface and a public-facing `Volume Mixer` lock entry

The missing piece is not “some hidden Pro switch.” The missing piece is a public implementation contract.

## 3. Product intent

### 3.1 What this slice is

This slice is:

- an architecture discovery feature
- a public contract-definition step for a missing reimplementation
- a bridge between roadmap intent and future engineering execution
- the work that makes later mixer implementation honest and reviewable

### 3.2 What this slice is not

This slice is not:

- a full per-app mixer release
- a hidden-feature unlock
- a promise that every app can immediately be controlled independently
- a UI polish pass disconnected from native feasibility
- a redesign of the current volume or outputs sections

## 4. Problem statement

`eqMacFree` documents `Volume Mixer` as a missing reimplementation and already routes users to it through the shared Lock UX. However, the public repository does not yet define the actual architecture for delivering it.

The current state has three useful but incomplete pieces:

1. **Client tracking exists natively**  
   The driver registers and removes clients using `EQM_AddDeviceClient` / `EQM_RemoveDeviceClient`, stores them in `EQMClients`, and passes a resolved `EQMClient?` into `EQMDevice.doIO`.

2. **Volume transport exists conceptually**  
   The app already exposes `/volume` routes through `EngineDataBus`, and the Angular UI already uses `VolumeService`, `BoosterService`, and `BalanceService` to communicate with the native layer.

3. **User-facing demand already exists**  
   The public app’s Help section exposes `Volume Mixer` as a locked future feature and routes users to roadmap / feature-request paths.

What is missing is the feature contract between those pieces:

- what exactly counts as a mixable client entry
- how client identity is stabilized across `clientId`, `processId`, and `bundleId`
- how per-client state would be stored and surfaced
- where native routes would live under the existing data-bus pattern
- what the first public UI should show before full live control is attempted

Without this slice, any direct implementation attempt would be guesswork.

## 5. Repo-grounded discoveries

This spec is based on current public repo evidence.

### 5.1 Native client-tracking evidence

Relevant files:

- `native/shared/Source/EQMClient.swift`
- `native/driver/Source/EQMClients.swift`
- `native/driver/Source/EQMInterface.swift`
- `native/driver/Source/EQMDevice.swift`

Observed facts:

- `EQMClient` currently stores:
  - `clientId`
  - `processId`
  - `bundleId`
- `EQMClients` can resolve clients by:
  - `clientId`
  - `processId`
  - `bundleId`
- `EQMInterface` registers/removes clients and resolves the current client before calling `EQMDevice.doIO`
- `EQMDevice.doIO` currently receives `client: EQMClient?` but does not yet apply a per-client mixing policy inside the ring-buffer logic

Important constraint discovered in code:

- `EQMClient.swift` shows partially prepared volume-oriented constructor/parsing shape, but the dictionary payload is not yet a complete, trustworthy per-client volume contract. That means the public repo contains **signals of intended direction**, not a finished subsystem.

### 5.2 Existing app route/data-bus evidence

Relevant files:

- `native/app/Source/ApplicationDataBus.swift`
- `native/app/Source/Audio/EngineDataBus.swift`
- `ui/src/app/services/volume.service.ts`
- `ui/src/app/sections/volume/booster-balance/booster/booster.service.ts`
- `ui/src/app/sections/volume/booster-balance/balance/balance.service.ts`

Observed facts:

- the app already mounts `/volume` from `EngineDataBus`
- UI services follow the existing `DataService` request/on/off pattern
- current volume functionality already fits this shape:
  - `GET /volume`
  - `POST /volume`
  - nested endpoints like `/gain`, `/balance`, `/boost/enabled`

This strongly suggests the future mixer should extend the existing `/volume` route family instead of inventing a separate subsystem.

### 5.3 Existing UI anchor evidence

Relevant files:

- `ui/src/app/sections/help/help.component.ts`
- `ui/src/app/services/lock-state.service.ts`
- `ui/src/app/app.component.ts`
- `ui/src/app/app.component.html`
- `ui/src/app/sections/volume/booster-balance/volume-booster-balance.component.ts`
- `ui/src/app/sections/outputs/outputs.component.ts`
- `ui/src/app/sections/outputs/outputs.service.ts`
- `ui/src/app/services/ui.service.ts`

Observed facts:

- the app currently has real live sections for:
  - master volume / booster / balance
  - outputs selection
- UI feature visibility is already controlled through `UIService.settings`
- `Volume Mixer` is already present as a future-facing Help entry via Lock UX

This suggests the future feature should first be introduced as a **new optional volume subsection**, not as a global navigation rewrite.

## 6. Product direction

The approved product direction for this slice is:

- keep `Volume Mixer` framed as a public missing reimplementation
- define the subsystem before attempting live controls
- preserve the repo’s current architecture style
- minimize the first future implementation slice so it can be verified in public

That means the first public implementation after this discovery work should likely be a **read-first or low-risk control** phase rather than a fully dynamic mixer with advanced persistence, grouping, or app icon catalog behavior.

## 7. Proposed architecture

### 7.1 Core concept

The future `Volume Mixer` feature should be defined as a **per-client volume surface layered on top of the existing engine volume pipeline**.

The long-term structure should have three layers:

1. **Client observation layer**  
   Tracks currently active audio clients and normalizes their identity.

2. **Per-client mixer state layer**  
   Represents app/client entries and target gain/mute state in a form the app/UI can reason about.

3. **UI presentation layer**  
   Displays those entries in the current Angular app using the existing section/service patterns.

### 7.2 Proposed data model

The first public contract should define a normalized mixer entry.

Recommended shape:

```ts
export interface VolumeMixerEntry {
  clientId: number
  processId: number
  bundleId: string | null
  name: string
  iconBundleId: string | null
  gain: number
  muted: boolean
  active: boolean
  controllable: boolean
}
```

Field meanings:

- `clientId`: low-level HAL/driver client identifier for the active session
- `processId`: current process identifier for live process correlation
- `bundleId`: preferred stable app identity when available
- `name`: user-facing label for the app/process entry
- `iconBundleId`: bundle to use for icon resolution in the existing UI app-service pattern
- `gain`: normalized scalar gain in the same general family as current volume UI state
- `muted`: explicit mute state for the entry
- `active`: whether the entry is currently present in the live graph
- `controllable`: whether the entry can safely accept control commands in the current implementation phase

### 7.3 Identity rules

The future implementation must not assume every client has a stable `bundleId`.

Recommended identity policy:

- treat `clientId` as the live session identifier
- use `bundleId` as the preferred grouping / display key when available
- use `processId` as a fallback correlation signal, not the only persistent identity
- avoid prematurely promising cross-relaunch persistence unless the public code proves it works

This is critical because the native code already shows multiple lookup paths, which implies identity is not always cleanly singular.

### 7.4 Native route contract

The future native app route should extend the existing `/volume` namespace.

Recommended first contract:

- `GET /volume/mixer` → list normalized entries
- `POST /volume/mixer/:clientId/gain` or equivalent request shape → set per-entry gain
- `POST /volume/mixer/:clientId/mute` or equivalent request shape → set per-entry mute state

Exact endpoint syntax can be finalized during implementation planning, but the contract should remain under `/volume`, not a disconnected top-level tree.

### 7.5 Native implementation boundary

This spec does **not** claim that per-client gain logic already exists.

Instead, it defines the implementation boundary clearly:

- `EQMClients` and `EQMInterface` already provide client awareness
- `EQMDevice.doIO` is the likely insertion point for per-client audio treatment or client-indexed state usage
- a future mixer-specific native state store will need to sit between client tracking and device I/O

The implementation plan should validate whether that state store belongs in:

- shared client metadata (`EQMClient` / companion state)
- a dedicated native mixer registry
- the app layer with driver coordination

The discovery slice must answer that question before coding starts.

### 7.6 UI surface direction

The future UI should follow existing app structure rather than adding a whole new navigation shell.

Recommended first UI placement:

- a new section under the current volume area
- feature-gated through `UIService.settings`, similar to existing visible sections
- list-based entries using current Angular component/service patterns

The first public implementation should prefer:

- app name
- icon
- gain control
- mute toggle

It should explicitly avoid in v1:

- grouping rules
- advanced sorting customization
- persistence promises not backed by the public code
- visual complexity beyond the existing app style

## 8. Scope

### 8.1 In scope for this discovery slice

- document current native client-tracking anchors
- document current app/UI transport anchors
- define the proposed mixer entry model
- define the likely route and UI integration shape
- identify the main implementation unknowns
- produce a concrete implementation plan for the next execution phase

### 8.2 Out of scope for this discovery slice

- writing the native mixer state registry
- adding live `/volume/mixer` routes
- rendering a live mixer section in the Angular UI
- shipping per-app gain/mute controls
- guaranteeing persistence or perfect app grouping behavior

## 9. Main implementation questions to answer next

The next implementation phase must explicitly answer these:

1. Should per-client state live in `EQMClient` itself or a separate registry?
2. What is the safest read-only path for listing active clients before enabling control writes?
3. How should app display names and icons be resolved when `bundleId` is missing?
4. How should stale clients disappear from the UI?
5. What minimal verification proves that a UI entry really corresponds to active audio traffic?

## 10. Acceptance criteria

This discovery feature is complete only when all of the following are true.

### 10.1 Design acceptance

- the spec documents the native client-tracking path already present in the public repo
- the spec defines a concrete proposed mixer entry model
- the spec defines the intended route namespace and UI placement
- the spec clearly distinguishes existing evidence from future implementation work

### 10.2 Planning acceptance

- there is a matching implementation plan in `docs/superpowers/plans/`
- that plan is scoped to discovery / architecture-definition work rather than pretending the full mixer ships immediately
- the plan names the concrete files to inspect or modify in the next phase

### 10.3 Boundary acceptance

- the feature remains framed as transparent public reimplementation work
- the docs do not imply hidden paid functionality is being unlocked
- the docs stay aligned with `docs/roadmap/lock-feature-backlog.md`

## 11. Verification strategy

This discovery slice should be verified at three levels.

### 11.1 Document verification

Confirm the spec and plan exist in the expected paths and follow the repo’s established naming and structure conventions.

### 11.2 Code-grounding verification

Confirm the architectural claims in this spec still map to the real codebase anchors:

- `EQMClient`
- `EQMClients`
- `EQMInterface`
- `EQMDevice.doIO`
- `EngineDataBus`
- `VolumeService`
- Help Lock entry and volume/output UI anchors

### 11.3 Repo-state verification

Confirm that adding this planning work does not disturb the clean post-merge working tree except for the new spec/plan files themselves.

## 12. Resulting next step

After this discovery slice, the next work should be a dedicated implementation phase for the smallest honest mixer milestone.

Recommended execution order after this spec:

1. native/client discovery implementation work
2. read-only mixer data exposure
3. basic UI list surface
4. first writable gain/mute control slice

That sequencing keeps the feature public, testable, and incremental.
