# eqMacFree Spatial Audio Headphone MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a testable first Spatial Audio UI for `eqMacFree` by adding a main-surface Spatial Audio card below `Volume/Balance`, backing it with persisted enabled/preset state, and making the native output path audibly react to `Cinema`, `Music`, and `Voice` presets.

**Architecture:** Keep the driver and stereo device contract unchanged. Implement Spatial Audio entirely in the app layer by extending the existing native settings contract, mapping presets to `AVAudioEnvironmentNode` behavior inside `Output.swift`, and exposing one shared state model through both a new Angular section component and the existing Settings screen. The main card is the primary control surface; Settings remains a secondary experimental mirror.

**Tech Stack:** Swift macOS app code, ReSwift state and DataBus routes, Angular/TypeScript UI sections, AVFoundation (`AVAudioEnvironmentNode`, `AVAudio3DMixing`), workspace ESLint, Angular production build, macOS `xcodebuild`.

---

## File structure map

- Modify: `native/app/Source/Settings/SettingsState.swift`
  - Add persisted `SpatialAudioPreset`, reducer support, and new preset action.
- Modify: `native/app/Source/Settings/SettingsDataBus.swift`
  - Add `GET/POST /spatial-audio-preset` routes alongside existing enabled routes.
- Modify: `native/app/Source/Settings/Settings.swift`
  - Mirror `spatialAudioEnabled` and `spatialAudioPreset`, rebuild the pipeline when either changes.
- Modify: `native/app/Source/Audio/Outputs/Output.swift`
  - Apply preset-specific spatial configuration and keep the disabled path intact.
- Create: `ui/src/app/sections/spatial-audio/spatial-audio.service.ts`
  - Wrap the Spatial Audio settings endpoints for the main-surface card.
- Create: `ui/src/app/sections/spatial-audio/spatial-audio.component.ts`
  - Own card state, collapse/expand behavior, enabled toggle, and preset switching.
- Create: `ui/src/app/sections/spatial-audio/spatial-audio.component.html`
  - Render the toolbar-style card with summary and preset controls using existing eqMac UI primitives.
- Create: `ui/src/app/sections/spatial-audio/spatial-audio.component.scss`
  - Keep styling aligned with existing section spacing and active/inactive states.
- Modify: `ui/src/app/app.component.ts`
  - Add the Spatial Audio section to height calculations and `ViewChild` tracking.
- Modify: `ui/src/app/app.component.html`
  - Insert the Spatial Audio card directly below `Volume/Balance`.
- Modify: `ui/src/app/app.module.ts`
  - Declare the new `SpatialAudioComponent`.
- Modify: `ui/src/app/sections/settings/settings.service.ts`
  - Add preset getter/setter methods for the Settings mirror.
- Modify: `ui/src/app/sections/settings/settings.component.ts`
  - Keep the existing checkbox, add preset selection mirror, and soften the wording to experimental/advanced.
- Optional modify: `ui/src/app/services/ui.service.ts`
  - Only if persisting the main-card collapsed state turns out to be worth the extra coupling.
- Reference: `ui/src/app/sections/effects/equalizers/equalizers.component.ts`
  - Existing collapse/expand and toolbar interaction pattern to mirror.
- Reference: `ui/src/app/sections/outputs/outputs.component.ts`
  - Example of a small single-purpose top-level section.
- Reference: `native/app/Source/Application.swift`
  - Existing audio pipeline rebuild path.

---

### Task 1: Lock the native Spatial Audio state contract

**Files:**
- Modify: `native/app/Source/Settings/SettingsState.swift`
- Modify: `native/app/Source/Settings/SettingsDataBus.swift`
- Modify: `native/app/Source/Settings/Settings.swift`

- [ ] **Step 1: Write a failing contract check for preset support**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
checks = {
  'native/app/Source/Settings/SettingsState.swift': ['SpatialAudioPreset', 'setSpatialAudioPreset'],
  'native/app/Source/Settings/SettingsDataBus.swift': ['/spatial-audio-preset'],
  'native/app/Source/Settings/Settings.swift': ['spatialAudioPreset']
}
for file, needles in checks.items():
    text = Path(file).read_text()
    print(file)
    for needle in needles:
        print(' ', needle, needle in text)
PY
```

Expected before implementation: at least one line prints `False`

- [ ] **Step 2: Add the preset type and reducer support in `SettingsState.swift`**

Implement the minimum persisted state shape:

```swift
enum SpatialAudioPreset: String, Codable, CaseIterable {
  case cinema = "cinema"
  case music = "music"
  case voice = "voice"
}

struct SettingsState: State {
  var iconMode: IconMode = .both
  @DefaultFalse var doCollectCrashReports = false
  @DefaultFalse var doAutoCheckUpdates = false
  @DefaultFalse var doOTAUpdates = false
  @DefaultFalse var doBetaUpdates = false
  @DefaultFalse var spatialAudioEnabled = false
  var spatialAudioPreset: SpatialAudioPreset = .music
}

enum SettingsAction: Action {
  case setIconMode(IconMode)
  case setDoCollectCrashReports(Bool)
  case setDoAutoCheckUpdates(Bool)
  case setDoOTAUpdates(Bool)
  case setDoBetaUpdates(Bool)
  case setSpatialAudioEnabled(Bool)
  case setSpatialAudioPreset(SpatialAudioPreset)
}
```

Update the reducer with:

```swift
case .setSpatialAudioPreset(let spatialAudioPreset)?:
  state.spatialAudioPreset = spatialAudioPreset
```

- [ ] **Step 3: Add preset GET/POST routes in `SettingsDataBus.swift`**

Add the new routes beside the enabled routes:

```swift
self.on(.GET, "/spatial-audio-preset") { data, _ in
  return [ "spatialAudioPreset": self.state.spatialAudioPreset.rawValue ]
}

self.on(.POST, "/spatial-audio-preset") { data, _ in
  let presetRaw = data["spatialAudioPreset"] as? String
  guard
    let presetRaw,
    let preset = SpatialAudioPreset(rawValue: presetRaw)
  else {
    throw "Invalid 'spatialAudioPreset' parameter, must be one of: cinema, music, voice"
  }

  Application.dispatchAction(SettingsAction.setSpatialAudioPreset(preset))
  return "Spatial Audio preset has been set"
}
```

- [ ] **Step 4: Rebuild on preset changes in `Settings.swift`**

Mirror the new static state and rebuild on both toggles:

```swift
static var spatialAudioEnabled = Application.store.state.settings.spatialAudioEnabled
static var spatialAudioPreset = Application.store.state.settings.spatialAudioPreset
```

In `newState(state:)`, add:

```swift
if state.spatialAudioPreset != Settings.spatialAudioPreset {
  Settings.spatialAudioPreset = state.spatialAudioPreset
  Console.log("Spatial Audio preset: \(Settings.spatialAudioPreset.rawValue)")
  Application.rebuildAudioPipeline()
}
```

Keep the existing enabled rebuild behavior; do not special-case one path and forget the other.

- [ ] **Step 5: Re-run the contract check and verify green**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
checks = {
  'native/app/Source/Settings/SettingsState.swift': ['SpatialAudioPreset', 'spatialAudioPreset', 'setSpatialAudioPreset'],
  'native/app/Source/Settings/SettingsDataBus.swift': ['/spatial-audio-preset', 'SpatialAudioPreset(rawValue:', 'setSpatialAudioPreset'],
  'native/app/Source/Settings/Settings.swift': ['spatialAudioPreset', 'Application.rebuildAudioPipeline()']
}
for file, needles in checks.items():
    text = Path(file).read_text()
    print(file)
    for needle in needles:
        print(' ', needle, needle in text)
PY
```

Expected after implementation: every relevant line prints `True`

- [ ] **Step 6: Commit the native state contract**

```bash
git add native/app/Source/Settings/SettingsState.swift native/app/Source/Settings/SettingsDataBus.swift native/app/Source/Settings/Settings.swift
git commit -m "feat: add spatial audio preset settings"
```

---

### Task 2: Make the native output path react to presets

**Files:**
- Modify: `native/app/Source/Audio/Outputs/Output.swift`
- Reference: `native/app/Source/Application.swift`

- [ ] **Step 1: Write a failing runtime-shape check**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
text = Path('native/app/Source/Audio/Outputs/Output.swift').read_text()
for needle in ['spatialAudioPreset', 'applySpatialAudioPreset', 'case .cinema', 'case .music', 'case .voice']:
    print(needle, needle in text)
PY
```

Expected before implementation: at least one line prints `False`

- [ ] **Step 2: Add a small preset configuration helper**

Create a focused helper inside `Output.swift`:

```swift
private struct SpatialAudioConfiguration {
  let sourcePosition: AVAudio3DPoint
  let reverbBlend: Float
  let rate: Float
}

private var spatialAudioPreset: SpatialAudioPreset {
  Application.store.state.settings.spatialAudioPreset
}

private func spatialAudioConfiguration(for preset: SpatialAudioPreset) -> SpatialAudioConfiguration {
  switch preset {
  case .cinema:
    return SpatialAudioConfiguration(
      sourcePosition: AVAudio3DPoint(x: 0, y: 0.2, z: -2.4),
      reverbBlend: 35,
      rate: initialVarispeedRate
    )
  case .music:
    return SpatialAudioConfiguration(
      sourcePosition: AVAudio3DPoint(x: 0, y: 0, z: -1.4),
      reverbBlend: 20,
      rate: initialVarispeedRate
    )
  case .voice:
    return SpatialAudioConfiguration(
      sourcePosition: AVAudio3DPoint(x: 0, y: 0, z: -0.8),
      reverbBlend: 5,
      rate: initialVarispeedRate
    )
  }
}
```

- [ ] **Step 3: Apply preset values to the environment node**

Refactor the current spatial configuration into an explicit preset-aware method:

```swift
private func applySpatialAudioPreset(_ preset: SpatialAudioPreset, source: AVAudioMixing) {
  let configuration = spatialAudioConfiguration(for: preset)
  source.renderingAlgorithm = .HRTF
  source.pointSourceInHeadMode = .mono
  source.position = configuration.sourcePosition
  source.reverbBlend = configuration.reverbBlend
  spatialEnvironment.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
}
```

Call it from the enabled path:

```swift
applySpatialAudioPreset(spatialAudioPreset, source: spatialSource)
```

- [ ] **Step 4: Keep the disabled path untouched**

Preserve the two operating modes:

```text
disabled:
player -> varispeed -> volume.mixer -> mainMixerNode

enabled:
spatial source node -> spatialEnvironment -> volume.mixer -> mainMixerNode
```

Do not widen the driver, change channel counts, or claim multichannel parity in code comments/logs.

- [ ] **Step 5: Re-run the runtime-shape check and verify green**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
text = Path('native/app/Source/Audio/Outputs/Output.swift').read_text()
checks = [
  ('preset property exists', 'spatialAudioPreset' in text),
  ('preset helper exists', 'spatialAudioConfiguration(for preset:' in text),
  ('apply helper exists', 'applySpatialAudioPreset' in text),
  ('cinema case exists', 'case .cinema:' in text),
  ('music case exists', 'case .music:' in text),
  ('voice case exists', 'case .voice:' in text),
]
for label, ok in checks:
    print(label, ok)
PY
```

Expected after implementation: every line prints `True`

- [ ] **Step 6: Build the macOS target and verify it compiles**

Run:

```bash
xcodebuild -workspace native/eqMac.xcworkspace -scheme eqMac -configuration Debug -derivedDataPath .build/eqmac-spatial CODE_SIGNING_ALLOWED=NO build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: Commit the preset-aware native runtime**

```bash
git add native/app/Source/Audio/Outputs/Output.swift
git commit -m "feat: apply spatial audio presets in native output"
```

---

### Task 3: Add the main-surface Spatial Audio card

**Files:**
- Create: `ui/src/app/sections/spatial-audio/spatial-audio.service.ts`
- Create: `ui/src/app/sections/spatial-audio/spatial-audio.component.ts`
- Create: `ui/src/app/sections/spatial-audio/spatial-audio.component.html`
- Create: `ui/src/app/sections/spatial-audio/spatial-audio.component.scss`
- Modify: `ui/src/app/app.component.ts`
- Modify: `ui/src/app/app.component.html`
- Modify: `ui/src/app/app.module.ts`

- [ ] **Step 1: Write a failing shell-integration check**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
checks = {
  'ui/src/app/app.component.html': ['eqm-spatial-audio'],
  'ui/src/app/app.component.ts': ['spatialAudio', 'SpatialAudioComponent'],
  'ui/src/app/app.module.ts': ['SpatialAudioComponent'],
  'ui/src/app/sections/spatial-audio/spatial-audio.component.ts': ['selector: \'eqm-spatial-audio\''],
}
for file, needles in checks.items():
    text = Path(file).read_text() if Path(file).exists() else ''
    print(file)
    for needle in needles:
        print(' ', needle, needle in text)
PY
```

Expected before implementation: at least one line prints `False`

- [ ] **Step 2: Create the section service**

Add a small wrapper that reuses the settings endpoints:

```ts
import { Injectable } from '@angular/core'
import { DataService } from 'src/app/services/data.service'

export type SpatialAudioPreset = 'cinema' | 'music' | 'voice'

@Injectable({ providedIn: 'root' })
export class SpatialAudioService extends DataService {
  route = `${this.route}/settings`

  async getEnabled(): Promise<boolean> {
    const { spatialAudioEnabled } = await this.request({ method: 'GET', endpoint: '/spatial-audio-enabled' })
    return spatialAudioEnabled
  }

  setEnabled(spatialAudioEnabled: boolean) {
    return this.request({ method: 'POST', endpoint: '/spatial-audio-enabled', data: { spatialAudioEnabled } })
  }

  async getPreset(): Promise<SpatialAudioPreset> {
    const { spatialAudioPreset } = await this.request({ method: 'GET', endpoint: '/spatial-audio-preset' })
    return spatialAudioPreset
  }

  setPreset(spatialAudioPreset: SpatialAudioPreset) {
    return this.request({ method: 'POST', endpoint: '/spatial-audio-preset', data: { spatialAudioPreset } })
  }
}
```

- [ ] **Step 3: Create the section component**

Implement the same broad interaction model as `EqualizersComponent`, but simpler:

```ts
import { Component, HostBinding, OnInit } from '@angular/core'
import { ApplicationService } from '../../services/app.service'
import { SpatialAudioPreset, SpatialAudioService } from './spatial-audio.service'

@Component({
  selector: 'eqm-spatial-audio',
  templateUrl: './spatial-audio.component.html',
  styleUrls: [ './spatial-audio.component.scss' ]
})
export class SpatialAudioComponent implements OnInit {
  toolbarHeight = 30
  presetsHeight = 52
  enabled = false
  show = true
  preset: SpatialAudioPreset = 'music'
  presets: SpatialAudioPreset[] = [ 'cinema', 'music', 'voice' ]

  @HostBinding('style.min-height.px') get height () {
    return this.toolbarHeight + (this.show ? this.presetsHeight : 0)
  }

  @HostBinding('style.max-height.px') get maxHeight () {
    return this.toolbarHeight + (this.show ? this.presetsHeight : 0)
  }

  constructor (
    public service: SpatialAudioService,
    public app: ApplicationService
  ) {}

  async ngOnInit () {
    const [ enabled, preset ] = await Promise.all([
      this.service.getEnabled(),
      this.service.getPreset()
    ])
    this.enabled = enabled
    this.preset = preset
  }

  toggleVisibility () {
    this.show = !this.show
  }

  async setEnabled (enabled: boolean) {
    this.enabled = enabled
    await this.service.setEnabled(enabled)
  }

  async selectPreset (preset: SpatialAudioPreset) {
    this.preset = preset
    await this.service.setPreset(preset)
  }

  presetLabel (preset: SpatialAudioPreset) {
    return ({
      cinema: 'Cinema',
      music: 'Music',
      voice: 'Voice'
    })[preset]
  }
}
```

- [ ] **Step 4: Create the section template and styles**

Render the card with an eqMac-like toolbar:

```html
<div fxLayout="row" class="toolbar w-100" [style.min-height.px]="toolbarHeight" fxLayoutAlign="space-between center">
  <div fxFlex="24" fxLayout="row" fxLayoutGap="10px" fxLayoutAlign="start center">
    <eqm-toggle [enabled]="app.enabled" [state]="enabled" (stateChange)="setEnabled($event)"></eqm-toggle>
  </div>

  <div fxLayout="row" fxLayoutAlign="center center" fxLayoutGap="8px">
    <eqm-label>Spatial Audio:</eqm-label>
    <eqm-label class="summary">{{ presetLabel(preset) }}</eqm-label>
  </div>

  <div fxFlex="10" fxLayout="row" fxLayoutAlign="end center">
    <eqm-icon (click)="toggleVisibility()" [name]="show ? 'hide' : 'show'"></eqm-icon>
  </div>
</div>

<div *ngIf="show" class="presets" fxLayout="row" fxLayoutGap="8px" fxLayoutAlign="center center">
  <eqm-label
    *ngFor="let candidate of presets"
    class="preset"
    [class.active]="candidate === preset"
    (click)="selectPreset(candidate)"
  >
    {{ presetLabel(candidate) }}
  </eqm-label>
</div>
```

Add matching styles:

```scss
:host {
  display: block;
}

.toolbar,
.presets {
  padding: 10px;
}

.preset,
.summary {
  cursor: pointer;
}

.preset.active {
  color: #5ac8fa;
}
```

- [ ] **Step 5: Wire the section into the app shell**

Update `app.module.ts`:

```ts
import { SpatialAudioComponent } from './sections/spatial-audio/spatial-audio.component'
```

and add `SpatialAudioComponent` to `declarations`.

Update `app.component.ts`:

```ts
import { SpatialAudioComponent } from './sections/spatial-audio/spatial-audio.component'

@ViewChild('spatialAudio', { static: false }) spatialAudio: SpatialAudioComponent
```

Update height calculations:

```ts
+ (this.spatialAudio ? (this.spatialAudio.height + divider) : 0)
```

and

```ts
+ (this.spatialAudio ? (this.spatialAudio.maxHeight + divider) : 0)
```

Update `app.component.html` so the new section sits directly below `eqm-volume-booster-balance`:

```html
<eqm-spatial-audio #spatialAudio></eqm-spatial-audio>
<eqm-divider></eqm-divider>
```

- [ ] **Step 6: Re-run the shell-integration check and verify green**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
checks = {
  'ui/src/app/app.component.html': ['<eqm-spatial-audio #spatialAudio></eqm-spatial-audio>'],
  'ui/src/app/app.component.ts': ['@ViewChild(\'spatialAudio\'', 'SpatialAudioComponent'],
  'ui/src/app/app.module.ts': ['SpatialAudioComponent'],
  'ui/src/app/sections/spatial-audio/spatial-audio.component.ts': ['selector: \'eqm-spatial-audio\'', 'presets: SpatialAudioPreset[] = [ \'cinema\', \'music\', \'voice\' ]'],
  'ui/src/app/sections/spatial-audio/spatial-audio.service.ts': ['getPreset()', 'setPreset(spatialAudioPreset: SpatialAudioPreset)'],
}
for file, needles in checks.items():
    text = Path(file).read_text()
    print(file)
    for needle in needles:
        print(' ', needle, needle in text)
PY
```

Expected after implementation: every relevant line prints `True`

- [ ] **Step 7: Lint and build the UI**

Run:

```bash
npm run lint
cd ui && npm run build
```

Expected:

```text
ESLint exits 0
Angular production build completes and writes ui/dist plus ui.zip
```

- [ ] **Step 8: Commit the main-surface card**

```bash
git add ui/src/app/app.component.ts ui/src/app/app.component.html ui/src/app/app.module.ts ui/src/app/sections/spatial-audio
git commit -m "feat: add spatial audio main card"
```

---

### Task 4: Mirror the controls in Settings and verify the full user flow

**Files:**
- Modify: `ui/src/app/sections/settings/settings.service.ts`
- Modify: `ui/src/app/sections/settings/settings.component.ts`
- Reference: `ui/src/app/sections/spatial-audio/spatial-audio.service.ts`

- [ ] **Step 1: Write a failing Settings-mirror check**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
service = Path('ui/src/app/sections/settings/settings.service.ts').read_text()
component = Path('ui/src/app/sections/settings/settings.component.ts').read_text()
checks = [
  ('service preset getter', 'getSpatialAudioPreset' in service),
  ('service preset setter', 'setSpatialAudioPreset' in service),
  ('component preset copy', 'Cinema' in component and 'Music' in component and 'Voice' in component),
  ('component sync preset', 'getSpatialAudioPreset()' in component),
]
for label, ok in checks:
    print(label, ok)
PY
```

Expected before implementation: at least one line prints `False`

- [ ] **Step 2: Add preset methods to `settings.service.ts`**

Add:

```ts
import { SpatialAudioPreset } from '../spatial-audio/spatial-audio.service'

async getSpatialAudioPreset(): Promise<SpatialAudioPreset> {
  const { spatialAudioPreset } = await this.request({ method: 'GET', endpoint: '/spatial-audio-preset' })
  return spatialAudioPreset
}

setSpatialAudioPreset({ spatialAudioPreset }: { spatialAudioPreset: SpatialAudioPreset }) {
  return this.request({ method: 'POST', endpoint: '/spatial-audio-preset', data: { spatialAudioPreset } })
}
```

- [ ] **Step 3: Add an experimental preset selector to `settings.component.ts`**

Keep the existing checkbox, but add a select option next to it:

```ts
import { SpatialAudioPreset } from '../spatial-audio/spatial-audio.service'

spatialAudioPresetOption: SelectOption<SpatialAudioPreset> = {
  type: 'select',
  label: 'Spatial Audio Preset',
  options: [
    { id: 'cinema', label: 'Cinema' },
    { id: 'music', label: 'Music' },
    { id: 'voice', label: 'Voice' }
  ],
  selectedId: 'music',
  isEnabled: () => this.spatialAudioOption.value,
  selected: spatialAudioPreset => {
    this.settingsService.setSpatialAudioPreset({ spatialAudioPreset })
  }
}
```

Update the existing tooltip copy so it reads as secondary/experimental:

```text
Main testing entry point is the Spatial Audio card on the main screen.
This Settings control mirrors the same experimental headphone-first state.
```

Add both controls to the settings layout:

```ts
[ this.spatialAudioOption, this.spatialAudioPresetOption ],
```

- [ ] **Step 4: Sync the preset value on load**

Extend `syncSettings()`:

```ts
const spatialAudioPreset = await this.settingsService.getSpatialAudioPreset()
this.spatialAudioPresetOption.selectedId = spatialAudioPreset
```

- [ ] **Step 5: Re-run the Settings-mirror check and verify green**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
service = Path('ui/src/app/sections/settings/settings.service.ts').read_text()
component = Path('ui/src/app/sections/settings/settings.component.ts').read_text()
checks = [
  ('service preset getter', 'getSpatialAudioPreset' in service),
  ('service preset setter', 'setSpatialAudioPreset' in service),
  ('component select exists', 'Spatial Audio Preset' in component),
  ('component sync preset', 'getSpatialAudioPreset()' in component),
  ('component layout row', '[ this.spatialAudioOption, this.spatialAudioPresetOption ]' in component),
]
for label, ok in checks:
    print(label, ok)
PY
```

Expected after implementation: every line prints `True`

- [ ] **Step 6: Run the full verification pass**

Run:

```bash
npm run lint
cd ui && npm run build
xcodebuild -workspace native/eqMac.xcworkspace -scheme eqMac -configuration Debug -derivedDataPath .build/eqmac-spatial CODE_SIGNING_ALLOWED=NO build
```

Expected:

```text
all commands exit 0
```

Then manually verify:

```text
1. The main app shows a Spatial Audio card below Volume/Balance.
2. The card can be collapsed and expanded.
3. Toggling Spatial Audio on keeps the app responsive.
4. Switching Cinema/Music/Voice updates the visible selection immediately.
5. Opening Settings shows the same enabled state and preset value.
6. Restarting the app preserves both enabled state and preset choice.
```

- [ ] **Step 7: Commit the Settings mirror and final verification**

```bash
git add ui/src/app/sections/settings/settings.service.ts ui/src/app/sections/settings/settings.component.ts docs/superpowers/plans/2026-04-17-eqmac-free-spatial-audio-headphone-mvp.md
git commit -m "feat: mirror spatial audio controls in settings"
```

---

## Self-review notes

- Spec coverage:
  - main-surface card below `Volume/Balance`: Task 3
  - `On/Off + Cinema/Music/Voice`: Tasks 1, 2, 3, 4
  - Settings as experimental mirror: Task 4
  - native preset-aware audible path: Tasks 1 and 2
  - verification/buildability: Tasks 2, 3, and 4
- Placeholder scan:
  - no `TBD`, `TODO`, or “write tests later” placeholders remain
- Type consistency:
  - `SpatialAudioPreset` uses one raw-value set everywhere: `cinema`, `music`, `voice`
  - service method names align across native and Angular layers

