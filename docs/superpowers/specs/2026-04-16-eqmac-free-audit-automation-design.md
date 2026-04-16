# eqMacFree Audit Automation Design Spec

**Date:** 2026-04-16  
**Status:** Approved for planning  
**Source repo:** `/Volumes/ssd/opencode_workspace/eqMac/.worktrees/eqmac-free-phase1`  
**Project type:** Guardrail feature for public boundary verification

## 1. Summary

This spec defines the first Phase 2 follow-up feature for `eqMacFree`: **feature capability audit automation**.

The goal is not to implement missing audio functionality yet. The goal is to create a repeatable verification layer that keeps launch-critical documentation, UI copy, and native launch surfaces aligned with the real public `eqMacFree` product boundary.

The first version uses a **hybrid model**:

- a human checklist for release authors and contributors
- a lightweight automated audit command for repeatable checks

This feature exists to stop boundary drift. If future feature work accidentally reintroduces legacy eqMac infrastructure URLs, outdated repo references, or misleading `Pro`/premium wording into live launch surfaces, the audit should catch it before those changes spread.

## 2. Why this feature is first

The current repo already has:

- a launched public `eqMacFree` repository
- Phase 1 feature inventory and backlog docs
- a clean separation between `available now`, `lock candidates`, and `missing reimplementation`

The next failure mode is not “missing one feature.” The next failure mode is that future work quietly drifts the repo back into inconsistent product messaging:

- README says one thing
- roadmap says another
- UI surfaces say a third thing
- native launch surfaces quietly point back to legacy infrastructure

Before shipping missing features one by one, `eqMacFree` needs a stable way to verify its own public boundary.

## 3. Product intent

### 3.1 What this feature is

This feature is:

- a repo-level guardrail
- a contributor-facing audit system
- a small verification layer for launch-critical surfaces
- a way to keep docs, UI copy, and native launch identity aligned

### 3.2 What this feature is not

This feature is not:

- a semantic static analyzer for the entire codebase
- a browser-based UI verification system
- a PR bot platform
- a private eqMac diff tool
- a shortcut to implementing missing audio features

## 4. Problem statement

`eqMacFree` now has an explicit public boundary:

- it is an independent public app derived from the last open snapshot
- it does not rely on legacy eqMac hosted UI, update feeds, or support routing for its Phase 1 launch identity
- it does not present unavailable functionality as secretly unlockable paid features

That boundary is currently encoded across multiple surfaces, but it is not yet guarded by a reusable audit system.

Without a boundary audit layer, future contributors can accidentally:

- reintroduce legacy eqMac URLs
- link back to the wrong GitHub repo or org
- expose ambiguous `Pro` language in live surfaces
- let README, roadmap, and UI wording drift apart
- leave `Lock` messaging inconsistent across files

## 5. Proposed approach

The first version will use three cooperating pieces.

### 5.1 Audit manifest

Create an explicit list of launch-critical file groups to audit.

The first version should cover:

- repo docs and metadata
  - `README.md`
  - `package.json`
  - `docs/roadmap/*.md`
  - selected `.github/**/*` text files where launch messaging matters
- UI surfaces
  - `ui/src/**/*.ts`
  - `ui/src/**/*.html`
  - selected config files that define public-facing routing or naming
- native launch surfaces
  - `native/app/Source/Constants.swift`
  - `native/app/Supporting Files/Info.plist`
  - `native/driver/Supporting Files/Info.plist`
  - selected Xcode project or scheme files only when they carry launch-visible identity or distribution wiring

The manifest exists to define **where boundary rules matter**. It should not attempt to scan every file in the repo.

### 5.2 Rule sets

The audit should classify rules into three groups.

#### Forbidden patterns

These are direct failures when found in active launch-critical surfaces.

Examples:

- `eqmac.app`
- `update.eqmac.app`
- `ui-v3.eqmac.app`
- `bitgapp/eqMac`
- `com.bitgapp.eqmac`
- `com.bitgapp.eqmac.driver`

#### Restricted wording

These require contextual handling.

Examples:

- `Pro`
- `Premium`
- `Upgrade`
- `promotion`

These are not globally banned in every file. They are banned in live launch surfaces unless the audit explicitly marks the surrounding file or rule context as an allowed exception.

#### Required alignment checks

These verify that major product boundary classifications stay consistent.

The first version should verify at least:

- README still distinguishes `available now`, `lock candidates`, and `missing reimplementation`
- roadmap docs still describe future work as reimplementation, not unlocking hidden code
- support/update links in UI/native launch surfaces still route to GitHub-backed public destinations or intentionally neutralized endpoints

### 5.3 Human checklist

The human checklist complements the automated audit.

Each contributor touching launch-critical surfaces should verify:

- did this change add or modify user-facing feature language?
- does README still match the roadmap buckets?
- does any live UI/native surface now imply unavailable functionality is active?
- did any legacy URL or old repo reference come back?
- does `Lock` still mean planned/unavailable rather than purchasable/unlockable?

This checklist should be short and stored in-repo near the audit documentation.

## 6. Audit scope

### 6.1 In scope for version 1

- explicit audit target list
- explicit boundary rules
- local command to run the audit
- clear pass/fail output
- known-good and known-bad verification cases
- contributor-facing documentation for how and when to run the audit

### 6.2 Out of scope for version 1

- full CI/GitHub Actions enforcement
- AST-aware semantic reasoning over all user-facing copy
- browser rendering verification
- automated verification that a missing feature is “really implemented”
- native runtime inspection outside text/config boundary surfaces

## 7. Architecture

### 7.1 Storage model

The first version should use plain-text, reviewable project artifacts.

Recommended shape:

- one manifest/config file describing scan targets and rules
- one human-readable doc describing the checklist and rule intent
- one executable script or command entrypoint that loads the manifest and reports failures

This keeps the system easy to review and easy to extend.

### 7.2 Execution model

The audit should be runnable with one local command.

Requirements:

- deterministic output
- non-zero exit code on hard failures
- clear distinction between hard failures, warnings, and allowed exceptions
- file-specific failure messages

### 7.3 Output model

The audit output should tell contributors:

- which rule failed
- which file triggered it
- whether the result is a hard fail or warning
- why the rule exists
- what kind of fix is expected

Bad output:

- vague “audit failed” messaging
- no file paths
- no boundary explanation

Good output:

- `Hard fail: legacy-hosted-url in native/app/Source/Constants.swift -> found update.eqmac.app`
- `Warning: lock-copy-drift in README.md -> wording no longer matches roadmap terminology`

## 8. Failure categories

### 8.1 Hard fail

Immediate correction required.

Examples:

- legacy hosted infrastructure URL returns to live launch surfaces
- old GitHub org/repo references return to launch surfaces
- `Pro`/premium wording returns to active UI/native copy in a way that implies unavailable paid functionality
- bundle identity or public support-routing surfaces drift back toward old eqMac infrastructure references

### 8.2 Soft fail / warning

Important mismatch, but not always an immediate block.

Examples:

- roadmap wording and README wording are slightly out of sync
- lock-state language is ambiguous instead of clearly planned/unavailable
- doc surfaces imply a future feature but do not classify it cleanly

### 8.3 Allowed exception

Explicitly documented safe context.

Examples:

- README historical/legal context explaining what `eqMacFree` is not
- design spec or implementation plan references to historical `Pro` naming
- attribution/credits sections naming original eqMac contributors or provenance

## 9. Verification strategy

This feature is complete only when it proves both pass and fail behavior.

### 9.1 Required proof

The implementation must show:

- a clean pass against the current intended launch boundary
- at least one intentional hard-fail example
- at least one intentional allowed-exception example

### 9.2 Suggested verification cases

Known-bad examples:

- add `https://eqmac.app` into a launch-critical UI constants file -> audit must fail
- add `bitgapp/eqMac` into README public-support section -> audit must fail

Known-allowed examples:

- historical `Pro` mention inside README explanatory section -> audit should allow or ignore according to the rule set
- provenance/credits mention of original eqMac project -> audit should allow

## 10. Developer workflow

Expected workflow for future contributors:

1. change README, roadmap, UI copy, or native launch surfaces
2. run the audit locally
3. fix hard failures
4. review warnings and resolve intentional drift
5. continue with normal verification

The audit should feel like a lightweight guardrail, not a second build system.

## 11. Definition of done

This Phase 2 feature is done when:

- audit target files are explicitly defined
- rules are explicitly defined and reviewable
- a local audit command exists and runs successfully
- hard fail, warning, and allowed-exception behavior are demonstrated
- contributor-facing guidance exists in repo docs
- the system is small enough that future feature work can extend it without redesigning it

## 12. Risks and mitigations

### 12.1 False positives

Risk:

- a naive string scanner flags valid historical references and becomes noisy

Mitigation:

- use scoped file groups
- separate forbidden vs restricted vs allowed rules
- keep explicit exception handling documented

### 12.2 Scope explosion

Risk:

- the first version tries to become a general repo linter

Mitigation:

- keep the target list launch-critical
- avoid whole-repo semantic analysis
- defer CI/platform work until local rules are stable

### 12.3 Weak adoption

Risk:

- contributors do not know the audit exists

Mitigation:

- document the workflow in a contributor-facing location
- keep the command short and predictable

## 13. Success criteria

This feature succeeds if it becomes the standard way to answer:

> Did this change accidentally break the public `eqMacFree` product boundary?

It should give a fast and actionable answer before larger Phase 2 feature work begins.
