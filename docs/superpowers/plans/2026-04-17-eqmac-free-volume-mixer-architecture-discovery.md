# eqMacFree Volume Mixer Architecture Discovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ground `Volume Mixer` in the public repo by documenting the real native/UI anchors, defining the future data contract, and producing an implementation-ready discovery package without shipping live mixer controls yet.

**Architecture:** Treat this phase as a code-grounded discovery pass, not a feature launch. Reuse the repo’s existing planning workflow and the existing native `DataBus` + Angular `DataService` architecture. The output of this plan is a verified design/update package that removes ambiguity for the first future mixer implementation slice.

**Tech Stack:** Markdown docs, Swift native audio driver/app code, Angular/TypeScript UI services and sections, existing roadmap/spec/plan conventions.

---

## File structure map

- Modify: `docs/roadmap/lock-feature-backlog.md` (only if discovery wording needs alignment)
  - Keep the backlog wording aligned with the documented next step for Volume Mixer.
- Create: `docs/superpowers/specs/2026-04-17-eqmac-free-volume-mixer-architecture-discovery-design.md`
  - Source-of-truth design spec for the Volume Mixer discovery slice.
- Create: `docs/superpowers/plans/2026-04-17-eqmac-free-volume-mixer-architecture-discovery.md`
  - Task-by-task implementation plan for the discovery slice.
- Reference: `native/shared/Source/EQMClient.swift`
  - Current client model and dictionary-conversion shape.
- Reference: `native/driver/Source/EQMClients.swift`
  - Client registry and lookup paths.
- Reference: `native/driver/Source/EQMInterface.swift`
  - Client registration/removal and route into device I/O.
- Reference: `native/driver/Source/EQMDevice.swift`
  - `doIO` boundary where future per-client mixer behavior would likely matter.
- Reference: `native/app/Source/ApplicationDataBus.swift`
  - Existing trusted route/data-bus root.
- Reference: `native/app/Source/Audio/EngineDataBus.swift`
  - Current `/volume` namespace mount point.
- Reference: `ui/src/app/services/volume.service.ts`
  - Existing Angular route root for volume-related data.
- Reference: `ui/src/app/sections/volume/booster-balance/booster/booster.service.ts`
  - Existing nested `/volume` service pattern for gain controls.
- Reference: `ui/src/app/sections/outputs/outputs.service.ts`
  - Existing device-list request pattern that a mixer list can mirror.
- Reference: `ui/src/app/services/ui.service.ts`
  - Existing feature visibility/settings pattern.
- Reference: `ui/src/app/sections/help/help.component.ts`
  - Current user-facing `Volume Mixer` lock entry.

---

### Task 1: Re-verify the roadmap and code anchors for Volume Mixer

**Files:**
- Reference: `docs/roadmap/lock-feature-backlog.md`
- Reference: `native/shared/Source/EQMClient.swift`
- Reference: `native/driver/Source/EQMClients.swift`
- Reference: `native/driver/Source/EQMInterface.swift`
- Reference: `native/driver/Source/EQMDevice.swift`
- Reference: `native/app/Source/ApplicationDataBus.swift`
- Reference: `native/app/Source/Audio/EngineDataBus.swift`
- Reference: `ui/src/app/services/volume.service.ts`
- Reference: `ui/src/app/sections/help/help.component.ts`

- [ ] **Step 1: Confirm the backlog still defines Volume Mixer as discovery-first work**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
text = Path('docs/roadmap/lock-feature-backlog.md').read_text()
needles = [
    '### 3. Volume mixer',
    'Investigate per-app volume architecture in the public codebase',
    'Define data model, native integration points, and UI surface',
    'Deliver as an isolated feature spec and implementation plan'
]
for needle in needles:
    print(needle, needle in text)
PY
```

Expected: all lines print `True`

- [ ] **Step 2: Confirm the native client-tracking path still exists in code**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
checks = {
  'native/shared/Source/EQMClient.swift': ['class EQMClient', 'clientId', 'processId', 'bundleId'],
  'native/driver/Source/EQMClients.swift': ['static var clients', 'get (clientId: UInt32)', 'get (processId: pid_t)', 'get (bundleId: String)'],
  'native/driver/Source/EQMInterface.swift': ['EQMClients.add(EQMClient(from: inClientInfo.pointee))', 'EQMClients.remove(client)', 'EQMClients.get(processId: inClientProcessID)', 'EQMClients.get(clientId: inClientID)'],
  'native/driver/Source/EQMDevice.swift': ['static func doIO (client: EQMClient?', 'switch operationID']
}
for file, needles in checks.items():
    text = Path(file).read_text()
    print(file)
    for needle in needles:
        print(' ', needle, needle in text)
PY
```

Expected: every check prints `True`

- [ ] **Step 3: Confirm the route/UI anchors still exist for future mixer work**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
checks = {
  'native/app/Source/ApplicationDataBus.swift': ['class ApplicationDataBus', 'self.add(EngineDataBus.self)'],
  'native/app/Source/Audio/EngineDataBus.swift': ['self.add("/volume", VolumeDataBus.self)'],
  'ui/src/app/services/volume.service.ts': ['route = `${this.route}/volume`'],
  'ui/src/app/sections/help/help.component.ts': ['Volume Mixer', "openVolumeMixerLock"],
}
for file, needles in checks.items():
    text = Path(file).read_text()
    print(file)
    for needle in needles:
        print(' ', needle, needle in text)
PY
```

Expected: every check prints `True`

- [ ] **Step 4: Write a short discovery note for yourself before drafting docs**

Record these conclusions in working notes before writing the spec:

```text
- Native client awareness exists already.
- Per-client mixer state does not yet have a complete public contract.
- /volume is the correct route family for a future mixer API.
- The Help lock entry is the real current user-facing anchor.
```

- [ ] **Step 5: Commit**

```bash
git status --short
```

Expected: no code changes yet, only note-taking if any local scratch file was used outside git.

---

### Task 2: Write the Volume Mixer design spec

**Files:**
- Create: `docs/superpowers/specs/2026-04-17-eqmac-free-volume-mixer-architecture-discovery-design.md`
- Reference: `docs/superpowers/specs/2026-04-16-eqmac-free-design.md`
- Reference: `docs/superpowers/specs/2026-04-16-eqmac-free-lock-state-ux-design.md`
- Reference: `docs/superpowers/specs/2026-04-16-eqmac-free-audit-automation-design.md`

- [ ] **Step 1: Create the design spec with the standard repo header**

Write the file with this opening structure:

```md
# eqMacFree Volume Mixer Architecture Discovery Design Spec

**Date:** 2026-04-17  
**Status:** Approved for planning  
**Source repo:** `/Volumes/ssd/opencode_workspace/eqMac`  
**Project type:** Missing-feature architecture discovery and public implementation-prep
```

- [ ] **Step 2: Write the summary, why-next, and product-intent sections**

The spec must explicitly say:

```md
The goal of this slice is not to ship a full per-app mixer yet.
The goal is to convert Volume Mixer from a roadmap placeholder into an implementation-ready public subsystem definition grounded in the current public codebase.
```

It must also restate that this is reimplementation work, not unlocking hidden paid code.

- [ ] **Step 3: Write the repo-grounded discovery section**

Include concrete references to:

```md
- native/shared/Source/EQMClient.swift
- native/driver/Source/EQMClients.swift
- native/driver/Source/EQMInterface.swift
- native/driver/Source/EQMDevice.swift
- native/app/Source/ApplicationDataBus.swift
- native/app/Source/Audio/EngineDataBus.swift
- ui/src/app/services/volume.service.ts
- ui/src/app/sections/help/help.component.ts
```

State clearly that:

```md
- native client tracking exists
- /volume already exists as a route namespace
- per-client mixer state is not yet a finished public contract
```

- [ ] **Step 4: Define the proposed data model and architecture boundaries**

Include a concrete interface block like:

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

Then explain the identity rules and the likely `/volume/mixer` route family.

- [ ] **Step 5: Write scope, acceptance criteria, and verification strategy**

The spec must keep the slice bounded to:

```md
- architecture discovery
- data-contract definition
- route/UI integration definition
- future implementation sequencing
```

and explicitly exclude:

```md
- live mixer controls
- native state-store implementation
- shipping a new UI section in this slice
```

- [ ] **Step 6: Self-review the spec inline**

Check for:

```text
- no TODO/TBD placeholders
- no hidden-feature/unlock framing
- no claims that per-app gain already works
- acceptance criteria match the scope
```

- [ ] **Step 7: Commit**

```bash
git add docs/superpowers/specs/2026-04-17-eqmac-free-volume-mixer-architecture-discovery-design.md
git commit -m "Add Volume Mixer discovery design spec"
```

---

### Task 3: Write the matching implementation plan

**Files:**
- Create: `docs/superpowers/plans/2026-04-17-eqmac-free-volume-mixer-architecture-discovery.md`
- Reference: `docs/superpowers/plans/2026-04-16-eqmac-free-phase-1-repo-launch.md`
- Reference: `docs/superpowers/plans/2026-04-16-eqmac-free-lock-state-ux-cleanup.md`
- Reference: `docs/superpowers/plans/2026-04-16-eqmac-free-audit-automation.md`

- [ ] **Step 1: Start the plan with the required plan header**

Use this exact shape:

```md
# eqMacFree Volume Mixer Architecture Discovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ground `Volume Mixer` in the public repo by documenting the real native/UI anchors, defining the future data contract, and producing an implementation-ready discovery package without shipping live mixer controls yet.
```

- [ ] **Step 2: Write a file-structure map with exact paths**

The plan must mention the actual reference files and their responsibilities, including:

```md
- native/shared/Source/EQMClient.swift
- native/driver/Source/EQMClients.swift
- native/driver/Source/EQMInterface.swift
- native/driver/Source/EQMDevice.swift
- native/app/Source/ApplicationDataBus.swift
- native/app/Source/Audio/EngineDataBus.swift
- ui/src/app/services/volume.service.ts
- ui/src/app/sections/volume/booster-balance/booster/booster.service.ts
- ui/src/app/sections/outputs/outputs.service.ts
- ui/src/app/services/ui.service.ts
- ui/src/app/sections/help/help.component.ts
```

- [ ] **Step 3: Break the work into bounded tasks**

The plan should include tasks for:

```text
1. Re-verify roadmap and code anchors
2. Write the design spec
3. Write the implementation plan
4. Verify docs and repo state
```

Each task must contain exact commands and expected outputs.

- [ ] **Step 4: Keep the plan discovery-only**

Do not add tasks that implement native routes or Angular mixer components.

Instead, write steps that produce:

```text
- a verified design package
- a verified planning package
- a clean handoff to the first future implementation phase
```

- [ ] **Step 5: Self-review the plan inline**

Check for:

```text
- no placeholders
- no skipped verification steps
- no mismatch between the spec scope and the plan scope
- all file paths are exact
```

- [ ] **Step 6: Commit**

```bash
git add docs/superpowers/plans/2026-04-17-eqmac-free-volume-mixer-architecture-discovery.md
git commit -m "Add Volume Mixer discovery implementation plan"
```

---

### Task 4: Verify the discovery package and repo state

**Files:**
- Verify: `docs/superpowers/specs/2026-04-17-eqmac-free-volume-mixer-architecture-discovery-design.md`
- Verify: `docs/superpowers/plans/2026-04-17-eqmac-free-volume-mixer-architecture-discovery.md`
- Reference: `docs/roadmap/lock-feature-backlog.md`

- [ ] **Step 1: Verify both new docs exist in the expected locations**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
files = [
  'docs/superpowers/specs/2026-04-17-eqmac-free-volume-mixer-architecture-discovery-design.md',
  'docs/superpowers/plans/2026-04-17-eqmac-free-volume-mixer-architecture-discovery.md',
]
for f in files:
    print(f, Path(f).exists())
PY
```

Expected: both print `True`

- [ ] **Step 2: Verify the new docs contain the required key phrases**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
checks = {
  'docs/superpowers/specs/2026-04-17-eqmac-free-volume-mixer-architecture-discovery-design.md': [
    'The goal of this slice is not to ship a full per-app mixer yet.',
    'VolumeMixerEntry',
    '/volume/mixer',
    'reimplementation work'
  ],
  'docs/superpowers/plans/2026-04-17-eqmac-free-volume-mixer-architecture-discovery.md': [
    '# eqMacFree Volume Mixer Architecture Discovery Implementation Plan',
    '### Task 1: Re-verify the roadmap and code anchors for Volume Mixer',
    '### Task 4: Verify the discovery package and repo state'
  ]
}
for file, needles in checks.items():
    text = Path(file).read_text()
    print(file)
    for needle in needles:
        print(' ', needle, needle in text)
PY
```

Expected: every check prints `True`

- [ ] **Step 3: Verify backlog alignment still holds**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
backlog = Path('docs/roadmap/lock-feature-backlog.md').read_text()
spec = Path('docs/superpowers/specs/2026-04-17-eqmac-free-volume-mixer-architecture-discovery-design.md').read_text()
phrases = [
    'Investigate per-app volume architecture in the public codebase',
    'Define data model, native integration points, and UI surface'
]
for phrase in phrases:
    print('backlog', phrase, phrase in backlog)
print('spec mentions public codebase', 'current public codebase' in spec)
print('spec mentions native integration points', 'native integration points' in spec or 'route and UI integration shape' in spec)
PY
```

Expected: all checks print `True`

- [ ] **Step 4: Verify git status reflects only the intended new docs**

Run:

```bash
GIT_MASTER=1 git status --short
```

Expected: only the new spec/plan files appear as uncommitted changes unless the backlog file was intentionally edited for wording alignment.

- [ ] **Step 5: Commit**

```bash
git status --short
```

Expected: the discovery package is fully reviewable and ready for either commit or user review.

---

## Handoff

When this discovery package is complete, the next implementation conversation should decide between two honest follow-up directions:

1. **Read-only mixer data slice** — list active clients/apps without writable controls yet
2. **First writable control slice** — minimal gain/mute control for a narrow, verified subset of entries

Do not skip directly to a full polished mixer UI without first validating the native read path.
