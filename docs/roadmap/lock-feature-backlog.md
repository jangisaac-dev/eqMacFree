# eqMacFree Lock Feature Backlog

This backlog turns unavailable historical capabilities into explicit follow-up engineering work for `eqMacFree`.

## Prioritization rules

Prioritize items that:

1. create clear user value without requiring private eqMac infrastructure
2. can be delivered independently in a public repo
3. do not depend on bypassing or restoring unavailable proprietary code
4. improve the app in small, verifiable releases

## Priority 1 — define and ship public-facing feature boundaries

### 1. Lock-state UX cleanup
- Replace any remaining ambiguous unavailable-feature copy with clear shared `Lock` wording
- Standardize how `Lock` surfaces explain “planned” vs “not yet implemented” without paid/unlock semantics
- Add a lightweight handoff from lock surfaces to roadmap/issues tracking

### 2. Feature capability audit automation
- Add a documented checklist or script for auditing user-facing references to unavailable features
- Keep launch docs, UI copy, and roadmap entries aligned as new work lands

## Priority 2 — high-value missing audio features

### 3. Volume mixer
- Investigate per-app volume architecture in the public codebase
- Define data model, native integration points, and UI surface
- Deliver as an isolated feature spec and implementation plan

### 4. Spectrum analyzer
- Research available signal-analysis hooks in the public app/driver stack
- Decide on rendering strategy and performance budget
- Build as a self-contained visualization feature

## Priority 3 — deeper DSP and plugin work

### 5. Expert EQ
- Define how it differs from existing advanced EQ
- Decide whether it extends the current EQ engine or introduces a new model
- Ship only after a dedicated spec and verification plan exist

### 6. AudioUnit hosting
- Investigate plugin-hosting constraints, UX, and sandbox implications
- Treat as a separate subsystem with dedicated planning and testing

### 7. Spatial audio
- Research feasibility against the current native audio pipeline
- Define a minimal public implementation before UI work starts

## Working rules for every backlog item

Before implementation, each feature should get:

- a written spec
- a scoped implementation plan
- an explicit verification strategy
- a decision on whether it is truly independent of private eqMac history

## Non-goals

The backlog is **not** a checklist for unlocking hidden code paths. It is a queue of new public engineering work to be built transparently in the open `eqMacFree` repo.
