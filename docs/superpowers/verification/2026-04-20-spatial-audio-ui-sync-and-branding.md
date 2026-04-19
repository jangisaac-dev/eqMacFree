# eqMacFree Spatial Audio UI Sync And Branding Notes

## Summary

This note records the follow-up work completed after driver and launch recovery:

- remaining user-facing `eqMac` strings were updated to `eqMacFree`
- the new Spatial Audio main card and the Settings mirror now stay in sync through one shared UI service state flow
- local verification required one UI build workaround because the workspace is currently using Node `v25.5.0` with an older Angular/Webpack toolchain

Use this note together with:

- `docs/superpowers/verification/2026-04-20-driver-and-launch-recovery.md`

## What Changed

### 1. User-facing branding cleanup

Updated microphone permission prompts in:

- `native/app/Source/Audio/Sources/Sources.swift`

Important visible string fixes:

- `eqMac needs access ...` -> `eqMacFree needs access ...`
- `No, quit eqMac` -> `No, quit eqMacFree`
- `Restart eqMac` -> `Restart eqMacFree`
- `eqMac.app` -> `eqMacFree.app`

This was intentionally limited to user-visible prompt text, not internal target names or legacy project file identifiers.

### 2. Spatial Audio UI state sync

Before this change:

- the main Spatial Audio card read enabled/preset state on init
- the Settings mirror also read state on its own
- changing one surface did not reliably update the other immediately

After this change:

- `ui/src/app/sections/spatial-audio/spatial-audio.service.ts`
  - owns shared `SpatialAudioState`
  - exposes `stateChanged`
  - adds `syncState()`
  - emits after `setEnabled()` and `setPreset()`
- `ui/src/app/sections/spatial-audio/spatial-audio.component.ts`
  - subscribes to shared state updates
  - shows `Off` when Spatial Audio is disabled
  - still preserves card collapse state via `UIService.showSpatialAudio`
- `ui/src/app/sections/settings/settings.component.ts`
  - now uses `SpatialAudioService` for Spatial Audio reads/writes
  - subscribes to shared state updates so the Settings mirror tracks main-card changes immediately

## Verification That Mattered

### Contract checks

```bash
cd /Volumes/ssd/opencode_workspace/eqMac
python3 - <<'PY'
from pathlib import Path
checks = {
  'ui/src/app/sections/spatial-audio/spatial-audio.service.ts': ['Subject', 'stateChanged', 'syncState'],
  'ui/src/app/sections/spatial-audio/spatial-audio.component.ts': ['summaryLabel', 'stateChangedSubscription', 'ngOnDestroy'],
  'ui/src/app/sections/settings/settings.component.ts': ['SpatialAudioService', 'stateChanged.subscribe', 'ngOnDestroy'],
  'native/app/Source/Audio/Sources/Sources.swift': ['eqMacFree needs access', 'quit eqMacFree', 'Restart eqMacFree', 'eqMacFree.app']
}
for file, needles in checks.items():
    text = Path(file).read_text()
    print(file)
    for needle in needles:
        print(' ', needle, needle in text)
PY
```

Expected result:

- every relevant line prints `True`

### UI lint

```bash
cd /Volumes/ssd/opencode_workspace/eqMac/ui
npm run lint
```

Observed result:

- passed cleanly

### UI build

Default build can fail on this machine because Angular 12 / Webpack 5 hits OpenSSL compatibility issues under Node `v25.5.0`.

Working command:

```bash
cd /Volumes/ssd/opencode_workspace/eqMac/ui
NODE_OPTIONS=--openssl-legacy-provider npm run build
```

Observed result:

- build succeeded
- warnings remained for existing unused TS compilation entries
- warning remained for the existing initial bundle budget overage

These warnings were pre-existing and did not block the build.

### App build and launch verification

```bash
cd /Volumes/ssd/opencode_workspace/eqMac
./script/build_and_run.sh --verify
```

Observed result:

- `** BUILD SUCCEEDED **`
- app process launched from the workspace-derived debug bundle

### Running process check

```bash
ps -axo pid=,args= | rg '/Volumes/ssd/opencode_workspace/eqMac/.build/eqmac-spatial/Build/Products/Debug/eqMacFree.app/Contents/MacOS/eqMacFree'
```

### Visible window check

```bash
osascript -e 'tell application id "dev.jangisaac.eqmacfree" to activate' \
  -e 'tell application id "dev.jangisaac.eqmacfree" to reopen'

osascript -e 'tell application "System Events" to tell process "eqMacFree" to get {frontmost, windows count}'
```

Observed result:

- `true, 1`

## Practical Next Step

If Spatial Audio work continues from here, check in this order:

1. main card still renders directly below `Volume/Balance`
2. toggle and preset changes reflect instantly in both main card and Settings
3. `NODE_OPTIONS=--openssl-legacy-provider npm run build` still succeeds for UI packaging
4. `./script/build_and_run.sh --verify` still launches the debug app bundle with a visible window

## Follow-up: Why The Main Spatial Audio Section Did Not Appear

The section was already present in Angular source, but the app still showed the old UI because the packaging and local-cache path were stale.

### Actual root causes

1. `ui/package.json` copied `ui.zip` to the wrong path:
   - old path: `native/app/Embedded`
   - correct path: `native/app/Assets/Embedded/ui.zip`
2. `UI.swift` looked for bundled UI in the wrong subdirectory:
   - old lookup: `Embedded`
   - correct lookup: `Assets/Embedded`
3. local UI cache reused the existing `ui-<version> (Local).zip` if the app version string had not changed
   - this masked UI-only changes during local iteration

### Fix applied

- `ui/package.json`
  - build now copies packaged UI into `native/app/Assets/Embedded/ui.zip`
- `native/app/Source/UI/UI.swift`
  - bundled fallback now reads from `Assets/Embedded`
  - local cached zip is replaced from the bundled zip on local-load path before unzip
- `script/build_and_run.sh`
  - local app run now rebuilds UI first using:

```bash
NODE_OPTIONS=--openssl-legacy-provider npm run build
```

### Verification for this fix

Check bundled zip content:

```bash
cd /Volumes/ssd/opencode_workspace/eqMac
python3 - <<'PY'
import zipfile
with zipfile.ZipFile('native/app/Assets/Embedded/ui.zip') as z:
    main = [n for n in z.namelist() if n.startswith('main.')][0]
    text = z.read(main).decode('utf-8', errors='ignore')
    for needle in ['eqm-spatial-audio', 'showSpatialAudio', 'cinema', 'voice']:
        print(needle, needle in text)
PY
```

Check refreshed local cache content after app launch:

```bash
cd /Volumes/ssd/opencode_workspace/eqMac
python3 - <<'PY'
import zipfile
path = '/Users/isaacjang/Library/Application Support/dev.jangisaac.eqmacfree/ui-1.3.2 (Local).zip'
with zipfile.ZipFile(path) as z:
    main = [n for n in z.namelist() if n.startswith('main.')][0]
    text = z.read(main).decode('utf-8', errors='ignore')
    for needle in ['eqm-spatial-audio', 'showSpatialAudio', 'cinema', 'voice']:
        print(needle, needle in text)
PY
```

Expected result:

- every line prints `True`

## Follow-up: Spatial Audio Quality Rework

The original public MVP sound path was not acceptable for real listening.

### Why it sounded bad

The first implementation:

- collapsed stereo into mono with `(L + R) / 2`
- spatialized that mono point source
- added reverb on top

That caused:

- the mix to lose stereo separation before spatial processing
- the center image to feel congested
- the original source to sound quieter or buried

### Fix applied

- `native/app/Source/Audio/Outputs/Output.swift`
  - keep the original stereo dry path alive through the existing `player -> varispeed` chain
  - add a separate wet spatial path on top instead of replacing the dry path
  - create left/right spatial source nodes instead of one mono node
  - tune presets by `dryMix`, `wetMix`, source positions, reverb amount, and channel crossfeed
  - keep the spatial graph attached even when disabled, so runtime preset/toggle changes only update mixer and source parameters
- `native/app/Source/Settings/Settings.swift`
  - stop calling `Application.rebuildAudioPipeline()` for spatial audio changes
  - call in-place `Application.updateSpatialAudioState()` instead
- `native/app/Source/Application.swift`
  - add in-place spatial state update entrypoint for the current live `Output`
- `ui/src/app/sections/spatial-audio/spatial-audio.component.*`
  - change the main Spatial Audio section to an equalizer-like pattern
  - use a preset dropdown instead of plain text chips
  - add an options button with preset descriptions

### Current preset intent

- `Music (Balanced)`
  - preserve the original mix most strongly
  - add only light width
- `Cinema (Wide)`
  - strongest stage widening
  - most obvious spatial effect
- `Voice (Clear)`
  - keep lead vocal / dialogue forward
  - use the lightest wet mix

### Verification used

```bash
cd /Volumes/ssd/opencode_workspace/eqMac/ui
npm run lint
NODE_OPTIONS=--openssl-legacy-provider npm run build
```

```bash
cd /Volumes/ssd/opencode_workspace/eqMac
./script/build_and_run.sh --verify
```

### Important behavioral note

After this fix:

- changing Spatial Audio preset should no longer tear down and recreate the audio pipeline
- toggling Spatial Audio on/off should no longer rebuild the full passthrough path
- this should remove the worst glitch/noise burst path and avoid output-device churn caused specifically by spatial preset/toggle actions

This does **not** change the broader eqMacFree routing model where enabling passthrough can still move system audio through the driver by design.

```bash
python3 - <<'PY'
import zipfile
path = '/Users/isaacjang/Library/Application Support/dev.jangisaac.eqmacfree/ui-1.3.2 (Local).zip'
with zipfile.ZipFile(path) as z:
    main = [n for n in z.namelist() if n.startswith('main.')][0]
    text = z.read(main).decode('utf-8', errors='ignore')
    for needle in ['Music (Balanced)', 'Cinema (Wide)', 'Voice (Clear)', 'eqm-dropdown', 'Preset Guide']:
        print(needle, needle in text)
PY
```
