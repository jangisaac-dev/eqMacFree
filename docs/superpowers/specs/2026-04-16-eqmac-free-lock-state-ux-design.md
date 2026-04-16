# eqMacFree Lock-state UX Cleanup Design Spec

**Date:** 2026-04-16  
**Status:** Approved for planning  
**Source repo:** `/Volumes/ssd/opencode_workspace/eqMac/.worktrees/eqmac-free-phase1`  
**Project type:** UX contract and public-boundary cleanup feature

## 1. Summary

This spec defines the next Phase 2 follow-up feature for `eqMacFree`: **Lock-state UX cleanup**.

The goal is not to implement missing audio features yet. The goal is to standardize how unavailable historical capabilities are presented in the public `eqMacFree` app and to provide a consistent public handoff path from those locked surfaces to roadmap and issue tracking.

In the public `eqMacFree` build, features that were historically framed as `Pro`-gated should now be treated as:

- not included in the current public build
- planned for future public development
- clearly labeled as `Lock`
- connected to public roadmap/issues handoff instead of upgrade or payment messaging

This feature exists to make that contract visible and consistent across shared UI surfaces.

## 2. Why this feature is next

The repo already has:

- a launched public `eqMacFree` repository
- a Phase 1 boundary that removed legacy hosted-service/product-funnel behavior
- an audit automation feature that guards launch-critical public-boundary wording and routing
- backlog documentation that explicitly identifies `Lock-state UX cleanup` as the next product-boundary task

The next failure mode is not missing DSP implementation yet. The next failure mode is inconsistent unavailable-feature UX:

- one surface says `Lock`
- another still implies `Pro`
- another has no explanation at all
- another has no public handoff path

Before implementing larger missing features like Volume Mixer or Spectrum Analyzer, `eqMacFree` needs one consistent rule for how unavailable features are shown and how users are redirected into the public development flow.

## 3. Product intent

### 3.1 What this feature is

This feature is:

- a UX contract for unavailable features
- a shared `Lock` presentation standard
- a public roadmap/issues handoff pattern
- a cleanup pass over current launch-visible lock-state surfaces

### 3.2 What this feature is not

This feature is not:

- a missing-feature implementation project
- a hidden-feature unlock system
- a payment or upgrade funnel
- a full visual redesign
- a broad internal symbol-rename or architecture rewrite

## 4. Problem statement

`eqMacFree` now publicly defines unavailable historical capabilities as future public engineering work rather than private paid unlocks. However, that contract is not yet fully embodied in the app UX.

Without a dedicated Lock-state UX cleanup pass, the repo risks leaving users with mixed signals:

- some unavailable features look like old `Pro` leftovers
- some surfaces may expose a `Lock` label without enough explanation
- some surfaces may not provide any public next step
- some future feature entry points may drift into inconsistent copy or dead-end interactions

That is a product-boundary problem, not just a copy problem.

## 5. Approved product direction

The approved direction is:

- treat formerly `Pro`-blocked historical capabilities as **planned future work**
- present those unavailable capabilities as **Lock** in the public build
- standardize both the wording and the interaction model
- include a clickable public handoff path to roadmap and issue surfaces

The user explicitly chose the scoped version of this feature that includes:

- **wording/state standardization**
- **roadmap/issues handoff**

and does **not** include actual implementation of missing audio capabilities.

## 6. UX contract

### 6.1 Public state model

For the first version, the public user-facing state model should stay intentionally small.

User-facing states:

- `Available now`
- `Lock`

Internal planning language may still describe a capability as `planned`, but the user-facing unavailable state should remain `Lock` so the app does not fragment into multiple overlapping meanings such as `Unavailable`, `Coming soon`, `Premium`, or `Upgrade`.

### 6.2 Meaning of `Lock`

In `eqMacFree`, `Lock` means:

- this capability is not included in the current public build
- it may be developed later as explicit public roadmap work
- it is not hidden paid functionality waiting to be purchased or bypassed

### 6.3 User-facing wording rules

Lock surfaces should follow a shared wording contract.

Required user-facing meaning:

- label: `Lock`
- explanatory copy: this feature is not currently included in the public `eqMacFree` build
- expectation: this is future public development work, not a purchasable unlock

Recommended short explanatory copy:

> This feature is not included in the current eqMacFree public build. It is planned as future public roadmap work.

The exact wording can be refined during implementation, but the meaning above must remain stable.

### 6.4 Interaction contract

Lock is not just a passive badge. It should provide a public next step.

The v1 interaction model should support:

- visible `Lock` label/badge
- short explanatory text or tooltip/prompt state
- handoff path to roadmap
- handoff path to issue or feature-request surface

The handoff must route users into the open public workflow, not into a payment or upgrade flow.

## 7. First-pass implementation scope

The first version should target the smallest set of real files and surfaces that can establish the shared Lock contract.

### 7.1 Confirmed current anchors in the repo

Current repo anchors already discovered in the worktree:

- shared lock badge surface:
  - `modules/components/src/components/pro/pro.component.ts`
- shared component export surface:
  - `modules/components/src/components.module.ts`
- centralized public handoff URL source:
  - `ui/src/app/services/constants.service.ts`
- roadmap/public-boundary sources:
  - `docs/roadmap/lock-feature-backlog.md`
  - `docs/roadmap/phase-1-feature-inventory.md`
  - `README.md`

Current known state:

- `pro.component.ts` already renders visible text `Lock`
- the internal symbol and selector still retain old `Pro` naming (`ProComponent`, `eqm-pro`)
- `constants.service.ts` already routes to GitHub-backed repo/issues/releases URLs

### 7.2 In scope for version 1

The first pass should include:

- the shared lock presentation surface
- the shared handoff URL/copy source needed for roadmap/issues navigation
- at least one real consumer surface that uses the Lock contract end-to-end
- the minimal shared metadata/copy layer needed to keep Lock messaging consistent

### 7.3 Out of scope for version 1

The first pass should not include:

- implementation of Volume Mixer, Spectrum Analyzer, or any other missing feature
- broad app-wide visual redesign
- full rename of every internal `Pro` symbol or selector in the codebase
- global refactor of unrelated UI architecture
- upgrade, purchase, subscription, or payment flows

## 8. Architecture

### 8.1 Shared presentation layer

The current shared component in `modules/components/src/components/pro/pro.component.ts` should be reinterpreted as the shared Lock presentation entry, not as leftover paid-feature UI.

The first version should preserve Phase 2’s scope discipline:

- it may continue to use the existing internal component entry point if that is the safest path
- but the shared behavior should clearly represent the Lock contract
- the component should be able to support explanation and handoff behavior, not just label rendering

### 8.2 Shared metadata and copy

The first version should introduce or centralize the minimum metadata required to keep locked-feature UX consistent.

That metadata should support at least:

- feature key or lock-state identifier
- user-facing title/label
- short unavailable/planned description
- roadmap destination
- issue or feature-request destination

This should avoid hardcoding different Lock explanations in multiple unrelated UI surfaces.

### 8.3 Shared handoff source

The first version should build on the existing public GitHub-backed routing source in:

- `ui/src/app/services/constants.service.ts`

The Lock-state UX should reuse centralized public routes instead of introducing one-off URLs in individual surfaces.

## 9. Acceptance criteria

This feature is complete only when all of the following are true.

### 9.1 User-facing acceptance

- live unavailable-feature surfaces use `Lock` instead of `Pro` / `Premium` / `Upgrade`
- the meaning of `Lock` is consistently “not included in the current public build”
- the UX clearly frames the feature as future public roadmap work, not purchasable access
- a user can reach both roadmap and issue/request destinations from the Lock interaction path

### 9.2 Implementation acceptance

- there is a shared Lock presentation path
- there is a shared source for the public handoff links used by Lock UX
- there is a reusable copy/metadata structure or equivalent minimal shared layer
- at least one real consumer surface demonstrates the full contract end-to-end

### 9.3 Boundary acceptance

- the implementation does not reintroduce `Pro`, `Premium`, `Upgrade`, or promotion-style public-funnel messaging into live launch surfaces
- the implementation remains consistent with the existing `eqMacFree` public-boundary docs and roadmap framing
- the existing audit automation can continue to verify the public boundary without special-casing this feature into ambiguity

## 10. Verification strategy

The first version should be verified across three layers.

### 10.1 UX verification

Check that at least one real Lock consumer surface shows:

- Lock label
- explanatory unavailable/planned copy
- roadmap handoff
- issue/request handoff

### 10.2 Boundary verification

Check that the handoff destinations actually route to the `eqMacFree` public surfaces, not to old eqMac or private/purchase flows.

### 10.3 Repo verification

Check that the feature does not create new public-boundary wording drift.

At minimum, the implementation should be safe against:

- live `Pro` copy leaks
- broken roadmap/issues routing
- divergent Lock wording across first-pass consumer surfaces

## 11. Risks and mitigations

### 11.1 Risk: badge-only cleanup without real interaction

If the work only changes a label and does not add a real public handoff path, the UX remains a dead end.

Mitigation:

- require roadmap/issues handoff as part of the definition of done

### 11.2 Risk: too much internal rename churn

If this feature tries to rename every internal `Pro` symbol or selector in one pass, it can turn into a broad refactor unrelated to the user-facing contract.

Mitigation:

- allow limited preservation of internal names in v1 if the user-facing Lock contract is correctly implemented

### 11.3 Risk: multiple inconsistent lock explanations

If different surfaces describe Lock differently, the product contract stays unclear.

Mitigation:

- centralize minimal copy/metadata for the first pass

### 11.4 Risk: accidental drift into feature implementation

This feature can expand uncontrollably if it starts implementing missing capabilities instead of standardizing unavailable-state UX.

Mitigation:

- keep missing feature work explicitly out of scope

## 12. Success criteria

This feature is successful when `eqMacFree` behaves like an honest public product boundary:

- unavailable historical capabilities are visibly framed as `Lock`
- those Lock surfaces say “planned future public work,” not “buy this”
- users are routed into open roadmap/issues tracking instead of upgrade funnels
- the shared Lock contract is strong enough that future missing features can reuse it instead of inventing their own unavailable-state UX
