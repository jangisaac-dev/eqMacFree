# eqMacFree Lock-state UX Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Standardize `Lock` presentation for unavailable historical features in `eqMacFree`, including shared wording and roadmap/issues handoff on at least one real consumer surface.

**Architecture:** Keep the first version small and anchored to existing UI patterns. Reuse the current shared badge component, existing GitHub-backed route constants, and the app’s existing Angular Material dialog pattern to introduce one reusable Lock metadata layer plus one real end-to-end consumer flow.

**Tech Stack:** Angular, TypeScript, existing shared components module, Angular Material dialogs, existing `ConstantsService`, existing boundary audit command.

---

## File structure map

- Modify: `modules/components/src/components/pro/pro.component.ts`
  - Keep the current shared Lock badge anchor, but make it support a clearer presentation contract instead of acting like a bare label only.
- Modify: `modules/components/src/components.module.ts`
  - Keep exports aligned with any shared Lock-state presentation pieces introduced in the components module.
- Create: `ui/src/app/services/lock-state.service.ts`
  - Centralize Lock metadata, explanatory copy, and handoff destinations per feature key.
- Create: `ui/src/app/components/lock-state-dialog/lock-state-dialog.component.ts`
  - Provide a reusable dialog controller for roadmap/issues handoff using the existing confirm-dialog pattern.
- Create: `ui/src/app/components/lock-state-dialog/lock-state-dialog.component.html`
  - Render shared Lock explanation and two-action public handoff UI.
- Modify: `ui/src/app/app.module.ts`
  - Register the new Lock-state dialog component.
- Modify: `ui/src/app/services/constants.service.ts`
  - Add any minimal public route constants needed by Lock UX, without introducing product-funnel URLs.
- Modify: `ui/src/app/sections/help/help.component.ts`
  - Add one real first-pass consumer path that opens the Lock UX contract end-to-end.
- Modify: `ui/src/app/sections/help/help.component.html`
  - Expose the first-pass Lock interaction entry point in the live app surface.
- Modify: `README.md`
  - Add a concise note that lock surfaces route to roadmap/issues rather than upgrade flows.
- Modify: `docs/roadmap/lock-feature-backlog.md`
  - Keep wording aligned with the implemented Lock UX contract if needed.

---

### Task 1: Add shared Lock metadata and public route contract

**Files:**
- Create: `ui/src/app/services/lock-state.service.ts`
- Modify: `ui/src/app/services/constants.service.ts:6-15`
- Test/Verify: `ui/src/app/services/lock-state.service.ts`, `ui/src/app/services/constants.service.ts`

- [ ] **Step 1: Verify the metadata layer does not exist yet**

Run:

```bash
test -f ui/src/app/services/lock-state.service.ts && exit 1 || echo "lock-state service missing as expected"
```

Expected: prints `lock-state service missing as expected`

- [ ] **Step 2: Add minimal shared route constants for Lock UX**

Update `ui/src/app/services/constants.service.ts` so the public route source includes explicit roadmap and feature-request destinations that Lock UX can reuse.

Target shape:

```ts
export class ConstantsService {
  readonly GITHUB_OWNER = 'jangisaac-dev'
  readonly REPO_NAME = 'eqMacFree'
  readonly DOMAIN = 'github.com'
  readonly REPO_URL = new URL(`https://${this.DOMAIN}/${this.GITHUB_OWNER}/${this.REPO_NAME}`)
  readonly FAQ_URL = new URL(`${this.REPO_URL.toString()}#readme`)
  readonly FEATURES_URL = new URL(`${this.REPO_URL.toString()}#available-now`)
  readonly ROADMAP_URL = new URL(`${this.REPO_URL.toString()}/blob/main/docs/roadmap/lock-feature-backlog.md`)
  readonly RELEASES_URL = new URL(`${this.REPO_URL.toString()}/releases`)
  readonly BUG_REPORT_URL = new URL(`${this.REPO_URL.toString()}/issues/new/choose`)
  readonly FEATURE_REQUEST_URL = new URL(`${this.REPO_URL.toString()}/issues/new/choose`)
}
```

Keep existing repo-backed URLs intact. Do not add any upgrade/purchase/pro URLs.

- [ ] **Step 3: Create the shared Lock metadata service**

Create `ui/src/app/services/lock-state.service.ts` with a very small, explicit contract.

Target shape:

```ts
import { Injectable } from '@angular/core'
import { ConstantsService } from './constants.service'

export type LockFeatureKey = 'volume-mixer'

export interface LockStateDefinition {
  key: LockFeatureKey
  label: string
  title: string
  description: string
  roadmapUrl: URL
  issueUrl: URL
}

@Injectable({
  providedIn: 'root'
})
export class LockStateService {
  constructor (private readonly CONST: ConstantsService) {}

  private readonly definitions: Record<LockFeatureKey, LockStateDefinition> = {
    'volume-mixer': {
      key: 'volume-mixer',
      label: 'Lock',
      title: 'Volume Mixer',
      description: 'This feature is not included in the current eqMacFree public build. It is planned as future public roadmap work.',
      roadmapUrl: this.CONST.ROADMAP_URL,
      issueUrl: this.CONST.FEATURE_REQUEST_URL
    }
  }

  getDefinition (key: LockFeatureKey): LockStateDefinition {
    return this.definitions[key]
  }
}
```

The first version only needs one real feature key so the contract is concrete and testable.

- [ ] **Step 4: Run a fast TypeScript parse check on the new service layer**

Run:

```bash
./node_modules/.bin/tsc -p ui/tsconfig.json --pretty false
```

Expected: no TypeScript errors from the new constants/service additions

- [ ] **Step 5: Commit**

```bash
git add ui/src/app/services/constants.service.ts ui/src/app/services/lock-state.service.ts
git commit -m "Add shared Lock metadata service"
```

---

### Task 2: Add reusable Lock handoff dialog

**Files:**
- Create: `ui/src/app/components/lock-state-dialog/lock-state-dialog.component.ts`
- Create: `ui/src/app/components/lock-state-dialog/lock-state-dialog.component.html`
- Modify: `ui/src/app/app.module.ts`
- Test/Verify: new dialog files + app module registration

- [ ] **Step 1: Confirm the dialog component does not exist yet**

Run:

```bash
test -f ui/src/app/components/lock-state-dialog/lock-state-dialog.component.ts && exit 1 || echo "lock-state dialog missing as expected"
```

Expected: prints `lock-state dialog missing as expected`

- [ ] **Step 2: Create the dialog component using the existing confirm-dialog pattern**

Create `ui/src/app/components/lock-state-dialog/lock-state-dialog.component.ts`.

Target shape:

```ts
import { Component, Inject } from '@angular/core'
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog'
import { ApplicationService } from 'src/app/services/app.service'
import { LockStateDefinition } from 'src/app/services/lock-state.service'

export interface LockStateDialogData {
  title: string
  description: string
  roadmapUrl: URL
  issueUrl: URL
}

@Component({
  selector: 'eqm-lock-state-dialog',
  templateUrl: './lock-state-dialog.component.html',
  styleUrls: [ './lock-state-dialog.component.scss' ]
})
export class LockStateDialogComponent {
  constructor (
    public dialogRef: MatDialogRef<LockStateDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: LockStateDialogData,
    private readonly app: ApplicationService
  ) {}

  openRoadmap () {
    this.app.openURL(this.data.roadmapUrl)
    this.dialogRef.close(true)
  }

  openIssueTracker () {
    this.app.openURL(this.data.issueUrl)
    this.dialogRef.close(true)
  }
}
```

This should reuse existing dialog infrastructure and avoid inventing a new interaction system.

- [ ] **Step 3: Create the dialog template**

Create `ui/src/app/components/lock-state-dialog/lock-state-dialog.component.html`.

Target shape:

```html
<div fxLayout="column" fxLayoutGap="10px">
  <eqm-label>{{data.title}}</eqm-label>
  <eqm-label style="white-space: pre-line;">{{data.description}}</eqm-label>
  <div fxLayout="row" fxLayoutGap="10px">
    <eqm-button type="narrow" fxFlex (pressed)="openRoadmap()">
      <eqm-label [clickable]="true">View roadmap</eqm-label>
    </eqm-button>
    <eqm-button type="narrow" fxFlex (pressed)="openIssueTracker()">
      <eqm-label [clickable]="true">Feature requests</eqm-label>
    </eqm-button>
  </div>
</div>
```

The wording can be polished during implementation, but it must remain public-roadmap/public-issue oriented.

- [ ] **Step 4: Register the new dialog in `ui/src/app/app.module.ts`**

Add `LockStateDialogComponent` to the imports/declarations/entry registration pattern already used by dialog components in the module.

Use the existing `PromptDialogComponent` and `ConfirmDialogComponent` registration style as the local pattern.

- [ ] **Step 5: Run a TypeScript parse/build check after registration**

Run:

```bash
./node_modules/.bin/tsc -p ui/tsconfig.json --pretty false
```

Expected: no TypeScript errors from the new dialog registration

- [ ] **Step 6: Commit**

```bash
git add ui/src/app/components/lock-state-dialog/lock-state-dialog.component.ts ui/src/app/components/lock-state-dialog/lock-state-dialog.component.html ui/src/app/app.module.ts
git commit -m "Add reusable Lock handoff dialog"
```

---

### Task 3: Connect one real consumer surface end-to-end

**Files:**
- Modify: `ui/src/app/sections/help/help.component.ts`
- Modify: `ui/src/app/sections/help/help.component.html`
- Modify: `modules/components/src/components/pro/pro.component.ts`
- Modify: `modules/components/src/components.module.ts` (only if needed for exports/imports)
- Test/Verify: help surface shows the Lock contract using shared data + dialog

- [ ] **Step 1: Add one real first-pass Lock entry in Help**

Use the Help section because it already opens public GitHub-backed routes and is a safe live consumer surface for the first Lock UX contract.

Update `ui/src/app/sections/help/help.component.ts` so its `options` includes a new button such as:

```ts
{
  type: 'button',
  label: 'Volume Mixer',
  action: this.openVolumeMixerLock.bind(this)
}
```

Add the supporting method and dialog usage:

```ts
import { MatDialog } from '@angular/material/dialog'
import { LockStateDialogComponent } from 'src/app/components/lock-state-dialog/lock-state-dialog.component'
import { LockStateService } from 'src/app/services/lock-state.service'

constructor (
  public app: ApplicationService,
  public CONST: ConstantsService,
  public ui: UIService,
  private readonly dialog: MatDialog,
  private readonly lockState: LockStateService
) {}

openVolumeMixerLock () {
  const definition = this.lockState.getDefinition('volume-mixer')

  this.dialog.open(LockStateDialogComponent, {
    data: {
      title: `${definition.title} · ${definition.label}`,
      description: definition.description,
      roadmapUrl: definition.roadmapUrl,
      issueUrl: definition.issueUrl
    }
  })
}
```

- [ ] **Step 2: Make the shared Lock badge more clearly reusable for this contract**

Keep `modules/components/src/components/pro/pro.component.ts` minimal, but add one optional input that makes the shared badge more presentation-ready for a live consumer surface.

Safe target change:

```ts
@Input() text = 'Lock'
```

and template:

```ts
<eqm-label [fontSize]="fontSize" [color]="color">{{text}}</eqm-label>
```

Do not rename `ProComponent` or `eqm-pro` in this first pass.

- [ ] **Step 3: Optionally surface the Lock badge in Help markup**

If the help entry needs visible context in HTML, add a small local label area in `help.component.html` that demonstrates the shared badge and makes the consumer path visibly testable.

Example pattern:

```html
<div fxLayout="row" fxLayoutGap="8px" fxLayoutAlign="center center">
  <eqm-label>Volume Mixer</eqm-label>
  <eqm-pro></eqm-pro>
</div>
```

Only add this if it improves visibility without cluttering the Help layout.

- [ ] **Step 4: Run the UI compile/build verification for the first real consumer path**

Run:

```bash
./node_modules/.bin/tsc -p ui/tsconfig.json --pretty false
NODE_OPTIONS=--openssl-legacy-provider yarn --cwd ui build
```

Expected:
- TypeScript compile passes
- Angular UI build passes

- [ ] **Step 5: Commit**

```bash
git add ui/src/app/sections/help/help.component.ts ui/src/app/sections/help/help.component.html modules/components/src/components/pro/pro.component.ts modules/components/src/components.module.ts ui/src/app/app.module.ts
git commit -m "Add first Lock-state UX consumer flow"
```

---

### Task 4: Align docs and boundary verification with the Lock UX contract

**Files:**
- Modify: `README.md`
- Modify: `docs/roadmap/lock-feature-backlog.md`
- Test/Verify: `yarn audit:boundary`

- [ ] **Step 1: Update README guardrail/product wording if needed**

Add a concise line in `README.md` that clarifies locked surfaces route into roadmap/issues instead of upgrade flows.

Safe target wording:

```md
- Locked historical capabilities should point users to roadmap/issues tracking rather than upgrade or purchase flows.
```

Place it near the feature inventory or guardrails section, whichever reads more naturally.

- [ ] **Step 2: Keep backlog wording aligned with the implemented UX contract**

Update `docs/roadmap/lock-feature-backlog.md` only if needed so the wording around `Lock-state UX cleanup` clearly matches what shipped:

- shared `Lock` wording
- roadmap/issues handoff
- no paid/unlock semantics

- [ ] **Step 3: Run boundary verification after the wording changes**

Run:

```bash
yarn audit:boundary
```

Expected:
- no new hard failures introduced by the Lock UX wording changes
- existing warning profile should stay acceptable or improve

- [ ] **Step 4: Commit**

```bash
git add README.md docs/roadmap/lock-feature-backlog.md
git commit -m "Document Lock-state UX contract"
```

---

## Self-review

Before execution, verify this plan against the spec:

1. **Spec coverage**
   - Shared Lock presentation path: covered by Task 2 + Task 3
   - Shared metadata/copy layer: covered by Task 1
   - Shared public handoff source: covered by Task 1
   - At least one real consumer surface: covered by Task 3 (`help.component.*`)
   - Boundary-safe wording: covered by Task 4

2. **Placeholder scan**
   - No `TBD`, `TODO`, “implement later,” “similar to Task N,” or missing-file placeholders remain in the task steps.

3. **Type consistency**
   - Shared key type: `LockFeatureKey`
   - Shared data shape: `LockStateDefinition`
   - Dialog input shape: `LockStateDialogData`
   - Consumer surface uses the same definition object instead of duplicating URL/copy strings.

## Execution handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-16-eqmac-free-lock-state-ux-cleanup.md`.

Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
