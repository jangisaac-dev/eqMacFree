# eqMacFree Driver And Launch Recovery

## Summary

This note records the exact recovery path for the `eqMacFree` app when it appears to fail with the driver incompatibility dialog or launches with no visible window.

The important lesson is:

- do not assume a reboot will fix it
- verify the real failure mode first
- there were multiple independent breakpoints stacked on top of each other

## Symptoms Seen

- App showed:
  - `The eqMacFree audio driver is incompatible`
- App process sometimes existed without a visible window
- After driver reinstall, the app still failed during launch

## Root Causes

### 1. Driver reinstall path had been dropped from the local run loop

Earlier working revisions installed the HAL driver as part of the local run script before launching the app.

That behavior had been lost, so the app could start against a stale system driver state.

Relevant history:

- `ee4e056 Restore driver build and surface install blocker`
- `1d379e9 Skip redundant driver reinstall on normal runs`

### 2. Driver install needed a different CoreAudio restart path

`launchctl kickstart -k system/com.apple.audio.coreaudiod` failed under SIP on this machine.

Working fallback:

- `sudo killall coreaudiod`

### 3. The app had a separate launch crash unrelated to the driver

After the driver path was corrected, the app still crashed because the storyboard still referenced the old module name `eqMac`.

Observed log evidence:

- `Unknown class '_TtC5eqMac14ViewController'`
- `Could not cast value of type 'NSViewController' to 'eqMacFree.ViewController'`

This made the failure look like a driver problem even when the actual blocker was nib/module mismatch.

## Files Changed To Recover

- `script/build_and_run.sh`
  - restored driver build/install before app launch
  - added `reinstall-driver` mode
  - compares installed driver version vs built driver version
  - uses `sudo killall coreaudiod` fallback when `launchctl kickstart` is blocked
- `native/driver/Driver.xcodeproj/project.pbxproj`
  - removed hard-failing driver post-build install script from the Xcode scheme path
  - aligned driver deployment target with the shared package floor
- `native/driver/Source/Bridge/EQMDriverBridge.m`
  - fixed generated Swift bridge header import name from `eqMac-Swift.h` to `eqMacFree-Swift.h`
- `native/app/Source/UI/Main.storyboard`
  - replaced `customModule="eqMac"` with `customModule="eqMacFree"`
- `native/Podfile`
  - restored a buildable `AMCoreAudio` path via local podspec
  - patched old `Sentry` and `AMCoreAudio` sources in `post_install` for current Xcode compatibility
- `native/AMCoreAudio-fixed.podspec`
  - fixes the public `AMCoreAudio` source glob so Swift sources actually install

## Verification That Mattered

### Driver version checks

Installed driver version:

```bash
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
  /Library/Audio/Plug-Ins/HAL/eqMacFree.driver/Contents/Info.plist
```

Built driver version:

```bash
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
  /Volumes/ssd/opencode_workspace/eqMac/.build/eqmac-driver/Build/Products/Debug/eqMacFree.driver/Contents/Info.plist
```

### App launch verification

```bash
cd /Volumes/ssd/opencode_workspace/eqMac
./script/build_and_run.sh --verify
```

### App process path verification

```bash
ps -axo pid=,args= | rg '/Volumes/ssd/opencode_workspace/eqMac/.build/eqmac-spatial/Build/Products/Debug/eqMacFree.app/Contents/MacOS/eqMacFree'
```

### Window visibility verification

```bash
osascript -e 'tell application id "dev.jangisaac.eqmacfree" to activate' \
  -e 'tell application id "dev.jangisaac.eqmacfree" to reopen'

osascript -e 'tell application "System Events" to tell process "eqMacFree" to get {frontmost, windows count}'
```

### Log signatures to distinguish causes

Driver mismatch text:

- `The eqMacFree audio driver is incompatible`

Nib/module mismatch text:

- `Unknown class '_TtC5eqMac14ViewController'`
- `Could not cast value ... to 'eqMacFree.ViewController'`

If the second pair appears, fix the storyboard module mapping first. Do not waste time on reboot advice.

## Current Recommended Run Commands

Normal run:

```bash
cd /Volumes/ssd/opencode_workspace/eqMac
./script/build_and_run.sh
```

Force driver reinstall:

```bash
cd /Volumes/ssd/opencode_workspace/eqMac
./script/build_and_run.sh reinstall-driver
```

## Practical Rule

When `eqMacFree` looks like a driver problem, always check in this order:

1. Is the built app actually the one running?
2. Is the installed driver version current?
3. Did the driver reinstall path run?
4. Did CoreAudio reload via `killall coreaudiod`?
5. Did the app actually crash on storyboard/module mismatch instead?

Do not jump straight to reboot as a default fix.
