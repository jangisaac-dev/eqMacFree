# eqMacFree Design Spec

**Date:** 2026-04-16  
**Status:** Approved for planning and phase-1 execution  
**Source repo:** `/Volumes/ssd/opencode_workspace/eqMac`  
**Project type:** Clean rebrand of public eqMac snapshot into a new public app and repository

## 1. Summary

`eqMacFree` is a new public macOS audio app derived from the public `eqMac` snapshot in this repository. The immediate goal is not to bypass Pro functionality. The goal is to launch a new independent public repository and app identity, then use that cleaned-up base to reimplement locked functionality one feature at a time.

Phase 1 creates the launchable public foundation:

- new app identity: `eqMacFree`
- clean rebrand of public surfaces
- `Pro` terminology replaced by `Lock`
- promotion / upsell / premium wording removed or rewritten
- explicit inventory of what exists now vs what must be reimplemented later
- seed backlog for future AI-driven feature work

After Phase 1, the project should be ready for public repository launch under the user's GitHub account and ready for iterative feature reimplementation work.

## 2. Repo Reality and Constraints

This spec is grounded in the current public repository, not in any private eqMac fork.

### 2.1 Evidence from current repo

- Root README states that this repository corresponds to **eqMac v1.3.2 without any Pro features** and that newer releases were developed in a private fork.
- README feature list still documents both Free and Pro features, including items not present in the public snapshot such as Expert EQ, Spectrum Analyzer, AudioUnit Hosting, Spatial Audio, and Volume Mixer.
- Public code contains some Pro-labeled scaffolding such as:
  - `modules/components/src/components/pro/pro.component.ts`
  - `modules/components/src/components.module.ts`
- Public equalizer implementation appears limited to Basic and Advanced tiers in current snapshot.
- Branding and infrastructure still point to eqMac / Bitgapp surfaces in multiple places, including:
  - root `package.json`
  - `README.md`
  - `CONTRIBUTING.md`
  - `SECURITY.md`
  - `CODE_OF_CONDUCT.md`
  - `.github/ISSUE_TEMPLATE/bug-report.md`
  - `.github/FUNDING.yml`
  - native app and driver `Info.plist`
  - native app and driver Xcode project files
  - Angular config and analytics strings

### 2.2 Concrete phase-1 branding surfaces already confirmed

The following currently contain eqMac-facing branding or distribution/support wiring and must be treated as real implementation inputs for Phase 1:

- repo metadata:
  - `package.json`
  - `.git/config` for local remote cleanup
- public docs/community:
  - `README.md`
  - `CONTRIBUTING.md`
  - `SECURITY.md`
  - `CODE_OF_CONDUCT.md`
  - `.github/ISSUE_TEMPLATE/bug-report.md`
  - `.github/FUNDING.yml`
- Angular UI surfaces:
  - `ui/src/index.html`
  - `ui/src/app/app.component.ts`
  - `ui/src/app/sections/header/header.component.html`
  - `ui/src/app/sections/header/header.component.ts`
  - `ui/src/app/sections/settings/settings.component.ts`
  - `ui/src/app/services/analytics.service.ts`
  - `ui/src/app/services/app.service.ts`
  - `ui/angular.json`
- shared components:
  - `modules/components/src/components/pro/pro.component.ts`
  - `modules/components/src/components.module.ts`
- native app config:
  - `native/app/Supporting Files/Info.plist`
  - `native/app/Source/Constants.swift`
  - `native/app/eqMac.xcodeproj/project.pbxproj`
  - `native/app/eqMac.xcodeproj/xcshareddata/xcschemes/eqMac.xcscheme`
- native driver config:
  - `native/driver/Supporting Files/Info.plist`
  - `native/driver/Driver.xcodeproj/project.pbxproj`

These surfaces include public repo URLs, support links, Discord links, analytics naming, Sparkle feeds, bundle identifiers, product names, driver install paths, and visible `Pro` labels.

### 2.3 Key constraint

Future work must treat missing Pro features as **new reimplementation work**, not as hidden features to crack or bypass.

## 3. Product Intent

### 3.1 What eqMacFree is

`eqMacFree` is:

- an independent public macOS audio app
- derived from the public eqMac snapshot
- community-friendly and repo-first
- built for incremental reimplementation of previously locked or absent features

### 3.2 What eqMacFree is not

`eqMacFree` is not:

- a piracy or bypass project
- a thin mirror of eqMac branding
- a promise to ship all former Pro features in Phase 1
- a sync-heavy upstream fork strategy

## 4. Naming, Branding, and Positioning

### 4.1 Working and public identity

- App name: `eqMacFree`
- Repository name: `eqMacFree`
- Launch style: new public repository under the user's account
- Repo strategy: **clean rebrand**, not long-term upstream-fork maintenance

### 4.2 Positioning language

Recommended public positioning:

> independent macOS audio app rebuilt from public snapshot

This keeps clear attribution context while emphasizing independent operation.

### 4.3 Credits and provenance

The project should preserve factual credits for the original public work and referenced upstream contributors, while avoiding presentation that implies official continuity with any private or proprietary eqMac release line.

### 4.4 Launch identity policy

Phase 1 should make the repository and application read as `eqMacFree` on the main public and user-facing surfaces, while avoiding unnecessary destructive renames of internal source structure that do not improve launch clarity.

Practical policy:

- rebrand public-facing names aggressively
- update bundle identifiers and product names where needed for independent app identity
- avoid folder churn or deep internal symbol churn unless required for build correctness or user-facing launch quality

## 5. Terminology Policy

Phase 1 introduces a language reset.

### 5.1 Required terminology changes

- `Pro` -> `Lock`
- `Premium` -> remove or replace with neutral roadmap language
- `Upgrade` -> remove where it implies payment funneling
- `Promotion` -> remove
- `Pro support` -> replace with community/support wording

### 5.2 Meaning of `Lock`

`Lock` means one of the following:

- feature surface exists but is not yet available in eqMacFree
- feature is planned for reimplementation
- feature belongs to future roadmap rather than current release

`Lock` must **not** imply that payment or bypass is expected.

## 6. Phase 1 Goal

Phase 1 goal:

> Launch `eqMacFree` as a new public repository and runnable app identity, with cleaned branding, repo artifacts, terminology reset, and a documented inventory/backlog for future lock-feature reimplementation.

## 7. Phase 1 Scope

### 7.1 In scope

- create or prepare new public GitHub repository launch artifacts for `eqMacFree`
- rebrand repo-level metadata and public documentation
- rebrand app-visible naming and obvious user-facing eqMac strings
- replace `Pro` wording with `Lock` where Phase 1 touches user-facing surfaces
- remove or rewrite promotion / upsell / premium-support wording
- review and update native app identity wiring needed for independent launch, including product naming, bundle identifiers, and distribution/update references where safe
- review and update driver identity wiring needed for independent launch, including product naming, install paths, and bundle identifiers where safe
- document feature inventory based on the public snapshot
- classify features into implementation buckets
- create initial backlog for future lock-feature work
- verify local build and launch path still works after Phase 1 changes

### 7.2 Out of scope

- implementing missing former Pro features
- bypassing hidden entitlements, licenses, or private-fork functionality
- redesigning the whole UI
- broad architectural rewrite unrelated to Phase 1 launch
- release automation beyond what is required to publish the new public repo cleanly

## 8. Feature Classification Model

All features must be classified into one of three buckets.

### 8.1 `available-now`

Functionality present and usable in the public snapshot.

Examples suggested by current repo evidence:

- system audio processing
- volume booster
- HDMI volume support
- volume balance
- basic EQ
- advanced EQ

### 8.2 `lock-candidate`

Feature surface, UI, terminology, or structural placeholder exists in the public snapshot, but the feature is incomplete, disabled, or needs explicit reopening/reframing for eqMacFree.

Examples likely include:

- Pro-labeled UI badges or copy
- feature visibility surfaces
- partial advanced feature hooks
- public snapshot surfaces that need repackaging under `Lock`

### 8.3 `missing-reimplementation`

Feature described in docs/history but not materially present in public code and therefore requiring new engineering work.

Examples likely include:

- Expert EQ
- Spectrum Analyzer
- AudioUnit Hosting
- Spatial Audio
- Volume Mixer

## 9. Milestones

### Milestone 1 — Repo Launch Skeleton

Deliverables:

- public repo identity defined for `eqMacFree`
- root metadata updated
- baseline README written for new project identity
- launch-oriented repo artifacts prepared

### Milestone 2 — Clean Rebrand

Deliverables:

- primary user-facing eqMac naming replaced with eqMacFree
- obvious eqMac links and repo references updated
- app-visible strings cleaned where safe in Phase 1

### Milestone 3 — Pro to Lock Transition

Deliverables:

- user-facing `Pro` wording removed or redefined as `Lock`
- promo / upgrade / premium-support surfaces removed or rewritten
- future features framed as roadmap and reimplementation work

### Milestone 4 — Inventory and Backlog Seed

Deliverables:

- documented inventory of public snapshot capabilities
- bucketed feature list using `available-now`, `lock-candidate`, `missing-reimplementation`
- first-pass backlog for future AI-led implementation

### Milestone 5 — Verification and Public Readiness

Deliverables:

- build path verified
- launch path smoke-tested
- docs consistent with new identity
- repo ready for public release under user account

## 10. File and Surface Categories to Touch

Phase 1 should treat branding work as four layers.

### 10.1 Repo / metadata layer

- root `package.json`
- README
- CONTRIBUTING and other community docs
- issue templates and repo metadata
- funding/support metadata

### 10.2 Documentation layer

- project description
- support wording
- roadmap language
- feature inventory and backlog docs

### 10.3 App-visible layer

- app name
- help/about/support text
- visible labels and badges
- any obvious promo text or update wording shown to users
- settings labels related to updates, telemetry, beta, uninstall, and support

### 10.4 Infrastructure / config layer

- bundle identifiers where safe to change in Phase 1
- analytics names
- update feed configuration review
- Angular app identifiers and build metadata
- Xcode product names, schemes, and entitlements references where launch identity depends on them
- driver install path and driver bundle naming where launch identity depends on them

### 10.5 Confirmed concrete strings and identities to evaluate

The current repo contains these concrete strings or identities that should be evaluated during Phase 1 implementation:

- `eqMac`
- `eqMac.app`
- `eqMac.driver`
- `com.bitgapp.eqmac`
- `com.bitgapp.eqmac.driver`
- `git+https://github.com/bitgapp/eqMac.git`
- `https://github.com/bitgapp/eqMac/issues`
- `https://github.com/bitgapp/eqMac#readme`
- `https://discord.eqmac.app`
- `https://eqmac.app`
- `https://update.eqmac.app/update.xml`
- `https://update.eqmac.app/beta-update.xml`
- `https://ui-v3.eqmac.app`
- Google Analytics tracker `UA-96287398-6`
- `Pro`
- `Beta Program`
- `OTA Updates`
- `Uninstall eqMac`

## 11. Verification Requirements

Phase 1 is complete only if all three verification groups pass.

### 11.1 Branding verification

- obvious `eqMac` branding removed from primary public surfaces that are supposed to be rebranded in Phase 1
- obvious `Pro` or payment-funnel wording removed from touched user-facing surfaces
- README consistently describes eqMacFree identity and project intent
- primary community and support documents no longer direct users to legacy eqMac branding by default unless preserved intentionally as attribution/history

### 11.2 Build verification

- relevant package metadata still parses
- UI build path still resolves after rename changes
- native app config remains internally coherent after text changes
- native Xcode project changes remain internally coherent for product naming, bundle IDs, entitlements references, and driver install paths
- no introduced diagnostics in edited code/config files

### 11.3 Product verification

- repository clearly reads as a new public app, not a cracked Pro fork
- roadmap distinguishes current features from future reimplementation work
- first backlog of lock-feature candidates exists for next-stage execution

## 12. Risks

### 12.1 Branding spread risk

eqMac naming is likely spread across docs, analytics, config, plists, and possibly Xcode project settings. Renaming shallowly may leave inconsistent public surfaces.

### 12.2 Public-vs-private mismatch risk

README feature claims may describe functionality that does not exist in this public snapshot. Inventory must follow code truth, not marketing text.

### 12.3 Native build coupling risk

Bundle identifiers, update feeds, or Xcode settings may be more tightly coupled than they appear from surface file inspection.

### 12.4 Legacy infrastructure risk

The public snapshot currently points at legacy eqMac domains, analytics, Sparkle feeds, and support channels. Phase 1 must decide whether to remove, replace, or temporarily neutralize each of these so the public repo does not launch with misleading live dependencies.

### 12.5 Scope explosion risk

Trying to implement locked features during Phase 1 would destabilize repo launch. Phase 1 must stop at launch-ready cleanup and backlog seeding.

## 13. Decision Rules

When tradeoffs appear during implementation, use these rules:

1. Prefer truthful public messaging over ambitious claims.
2. Prefer independent branding over upstream resemblance.
3. Prefer small verified launch changes over broad speculative rewrites.
4. Prefer inventory and backlog clarity over pretending missing features already exist.
5. Prefer feature-by-feature reimplementation plans after launch, not during Phase 1.

## 14. Phase 1 Done Definition

Phase 1 is done when all of the following are true:

1. `eqMacFree` repo launch artifacts are ready for a public repository under the user's account.
2. The codebase presents itself as `eqMacFree` on the main public surfaces touched in Phase 1.
3. `Pro` language has been replaced or reframed into `Lock` language on the primary user-facing surfaces touched in Phase 1.
4. Promotion and premium funnel wording has been removed or rewritten on touched surfaces.
5. A public-snapshot feature inventory exists with the three-bucket model.
6. A seed backlog exists for future lock-feature reimplementation.
7. Build and smoke verification for Phase 1 changes have passed.

## 15. Post-Phase-1 Follow-up

After Phase 1, work should continue as a repeated loop:

1. choose one lock feature or missing-reimplementation target
2. write focused spec/plan if needed
3. implement in isolation
4. verify
5. publish progress

Recommended first follow-up targets should favor high user value and relatively low native/system risk.

## 16. Explicit Assumptions

- The user wants execution to continue past spec approval, through planning and into Phase 1 repo-launch implementation, without pausing for another manual approval checkpoint.
- Git commits are not included unless the user explicitly requests them.
- Future missing former-Pro features will be treated as new engineering work, not as entitlement bypass work.
