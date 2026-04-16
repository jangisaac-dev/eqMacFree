# eqMacFree Phase 1 Repo Launch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebrand the public eqMac snapshot into an independent `eqMacFree` repo/app foundation with cleaned public messaging, Lock terminology, launch docs, and safe identity/config cleanup.

**Architecture:** Keep the Phase 1 diff focused on public-facing and launch-critical surfaces first: repo metadata/docs, visible UI copy, then native identity/config points that must stop presenting as the old product. Avoid deep source-tree churn or speculative refactors. Replace payment-funnel language with roadmap language, neutralize legacy live-service assumptions where safe, and add explicit inventory/backlog docs for post-launch feature reimplementation.

**Tech Stack:** Markdown docs, Yarn workspace metadata, Angular/TypeScript UI, shared Angular components, Swift native app, macOS plist/Xcode project configuration.

---

## File Structure Map

- `package.json` — root repo identity, repository URLs, monorepo description
- `README.md` — public project narrative, feature inventory summary, community links
- `CONTRIBUTING.md` / `SECURITY.md` / `CODE_OF_CONDUCT.md` / `.github/ISSUE_TEMPLATE/bug-report.md` / `.github/FUNDING.yml` — public contribution/support/contact surfaces
- `docs/superpowers/specs/2026-04-16-eqmac-free-design.md` — approved design source of truth
- `docs/roadmap/phase-1-feature-inventory.md` — concrete current/lock/missing feature inventory
- `docs/roadmap/lock-feature-backlog.md` — prioritized follow-up backlog after launch
- `ui/src/index.html` — browser title for the app UI shell
- `ui/src/app/app.component.ts` — privacy/telemetry text shown to users
- `ui/src/app/sections/header/header.component.html` / `header.component.ts` — main app title, bypass tooltip, quit wording
- `ui/src/app/sections/settings/settings.component.ts` — settings labels/tooltips for updates, telemetry, beta, uninstall
- `ui/src/app/services/analytics.service.ts` — analytics product naming
- `ui/src/app/services/app.service.ts` — uninstall URL behavior
- `ui/angular.json` — Angular project identity used by build targets
- `modules/components/src/components/pro/pro.component.ts` / `modules/components/src/components.module.ts` — shared visible Pro badge component that should become Lock
- `native/app/Supporting Files/Info.plist` — app metadata shown by macOS and Sparkle feed default
- `native/app/Source/Constants.swift` — trusted domains, update feeds, analytics/service endpoints, site links
- `native/app/eqMac.xcodeproj/project.pbxproj` / `native/app/eqMac.xcodeproj/xcshareddata/xcschemes/eqMac.xcscheme` — app product name, bundle ID, scheme name references
- `native/driver/Supporting Files/Info.plist` / `native/driver/Driver.xcodeproj/project.pbxproj` — driver identity, install path, product name references

### Task 1: Rebrand root repo metadata and launch docs

**Files:**
- Modify: `package.json`
- Modify: `README.md`
- Modify: `CONTRIBUTING.md`
- Modify: `SECURITY.md`
- Modify: `CODE_OF_CONDUCT.md`
- Modify: `.github/ISSUE_TEMPLATE/bug-report.md`
- Modify: `.github/FUNDING.yml`

- [ ] **Step 1: Write the failing content assertions by inspection**

```text
Expected failures before editing:
- package.json still says name=eqmac and points to bitgapp/eqMac
- README still markets Pro features as product tiers and points users to eqmac.app/Discord
- CONTRIBUTING still clones eqMac and opens eqMac.xcworkspace
- SECURITY and CODE_OF_CONDUCT still point to legacy eqmac.app contact endpoints
- bug-report template still says "improve eqMac" and instructs users to enable Beta Program in eqMac settings
- FUNDING.yml still references the original maintainer account
```

- [ ] **Step 2: Rewrite root package metadata for the new public identity**

```json
{
  "name": "eqmac-free",
  "description": "eqMacFree monorepo",
  "repository": {
    "type": "git",
    "url": "git+https://github.com/YOUR_USERNAME/eqMacFree.git"
  },
  "bugs": {
    "url": "https://github.com/YOUR_USERNAME/eqMacFree/issues"
  },
  "homepage": "https://github.com/YOUR_USERNAME/eqMacFree#readme"
}
```

- [ ] **Step 3: Replace README with truthful eqMacFree launch messaging**

```md
# eqMacFree

Independent macOS audio app rebuilt from the public eqMac snapshot.

## Project status
- Phase 1 launch base from the public open-source snapshot
- No Pro bypassing or license circumvention
- Missing former Pro features are tracked as future reimplementation work

## Feature inventory
- Available now: system audio processing, volume booster, HDMI volume, balance, basic EQ, advanced EQ
- Lock candidates: user-facing surfaces that still imply unavailable features
- Missing reimplementation: Expert EQ, Spectrum Analyzer, AudioUnit hosting, Spatial Audio, Volume Mixer

## Community
- Use GitHub Issues and Discussions for support
- This repo is an independent continuation of the public snapshot, not the private eqMac Pro line
```

- [ ] **Step 4: Rewrite contribution and community docs for eqMacFree**

```md
## Contribution
eqMacFree accepts focused pull requests against the public repo.

## Development
git clone https://github.com/YOUR_USERNAME/eqMacFree.git
cd eqMacFree/
```

```md
## Reporting a Security Vulnerability
Please open a private security advisory or contact the current project maintainer through the repository security contact documented in this repo.
```

```md
reported by contacting the project team through the eqMacFree repository maintainers.
```

- [ ] **Step 5: Rewrite issue/funding metadata to stop pointing at the old product owner**

```md
about: Create a report to help improve eqMacFree
```

```md
- [ ] I have checked for a similar issue and confirmed it has not already been reported.
- [ ] I tested against the latest eqMacFree snapshot available in this repository.
```

```yml
github:
custom: []
```

- [ ] **Step 6: Verify the edited public docs no longer default to legacy eqMac branding**

Run: `python3 - <<'PY'
from pathlib import Path
files = [
    'package.json','README.md','CONTRIBUTING.md','SECURITY.md','CODE_OF_CONDUCT.md',
    '.github/ISSUE_TEMPLATE/bug-report.md','.github/FUNDING.yml'
]
for f in files:
    text = Path(f).read_text()
    print(f, 'eqMacFree' in text, 'bitgapp/eqMac' in text, 'eqmac.app' in text)
PY`
Expected: `eqMacFree` present where appropriate; no default `bitgapp/eqMac` or `eqmac.app` launch guidance remains.

### Task 2: Clean visible UI branding and Pro-to-Lock language

**Files:**
- Modify: `ui/src/index.html`
- Modify: `ui/src/app/app.component.ts`
- Modify: `ui/src/app/sections/header/header.component.html`
- Modify: `ui/src/app/sections/header/header.component.ts`
- Modify: `ui/src/app/sections/settings/settings.component.ts`
- Modify: `ui/src/app/services/analytics.service.ts`
- Modify: `ui/src/app/services/app.service.ts`
- Modify: `ui/angular.json`
- Modify: `modules/components/src/components/pro/pro.component.ts`
- Modify: `modules/components/src/components.module.ts`

- [ ] **Step 1: Write the failing UI copy expectations by inspection**

```text
Expected failures before editing:
- Browser title still shows eqMac
- Header label still shows eqMac and eqMac Bypass
- Quit dialog still says "quit eqMac"
- Privacy and crash-report text still refer to eqMac and the old developer relationship
- Settings still expose "OTA Updates", "Beta Program", and "Uninstall eqMac"
- Shared badge component still renders "Pro"
- angular.json project name still uses eqmac
```

- [ ] **Step 2: Rename the visible app identity to eqMacFree**

```html
<title>eqMacFree</title>
<eqm-label> eqMacFree </eqm-label>
```

```ts
text: 'Are you sure you want to quit eqMacFree?'
```

- [ ] **Step 3: Replace payment-funnel language with Lock / roadmap wording**

```html
<eqm-toggle eqmTooltip="Audio processing: {{appEnabled ? 'Enabled' : 'Disabled'}}" ...></eqm-toggle>
```

```ts
label: 'Lock'
```

```ts
<eqm-label ...>Lock</eqm-label>
```

- [ ] **Step 4: Rewrite privacy, crash, and update settings copy to neutral project language**

```ts
label: 'Send anonymous usage telemetry'
```

```ts
tooltip: `
eqMacFree can collect anonymous usage data such as:

• macOS version
• app and UI version
• country derived from anonymized IP data

This helps maintainers understand how the public app is used.
`
```

```ts
label: 'UI content updates'
label: 'Preview updates'
label: 'Open uninstall guide'
```

- [ ] **Step 5: Neutralize analytics naming and uninstall routing assumptions**

```ts
appName: 'eqMacFree'
```

```ts
return this.openURL(new URL(`https://${this.CONST.DOMAIN}/uninstall`))
```

- [ ] **Step 6: Update Angular project identity without changing selector prefix churn**

```json
"projects": {
  "eqmac-free": {
```

```json
"browserTarget": "eqmac-free:build"
```

- [ ] **Step 7: Verify primary UI strings now reflect the new product boundary**

Run: `python3 - <<'PY'
from pathlib import Path
files = [
  'ui/src/index.html',
  'ui/src/app/app.component.ts',
  'ui/src/app/sections/header/header.component.html',
  'ui/src/app/sections/header/header.component.ts',
  'ui/src/app/sections/settings/settings.component.ts',
  'ui/src/app/services/analytics.service.ts',
  'ui/src/app/services/app.service.ts',
  'ui/angular.json',
  'modules/components/src/components/pro/pro.component.ts'
]
needles = ['eqMacFree', 'Lock']
for f in files:
    text = Path(f).read_text()
    print(f, {n: (n in text) for n in needles})
PY`
Expected: `eqMacFree` and `Lock` appear on the intended surfaces; removed phrases are absent from edited files.

### Task 3: Clean native app and driver launch identity/config

**Files:**
- Modify: `native/app/Supporting Files/Info.plist`
- Modify: `native/app/Source/Constants.swift`
- Modify: `native/app/eqMac.xcodeproj/project.pbxproj`
- Modify: `native/app/eqMac.xcodeproj/xcshareddata/xcschemes/eqMac.xcscheme`
- Modify: `native/driver/Supporting Files/Info.plist`
- Modify: `native/driver/Driver.xcodeproj/project.pbxproj`

- [ ] **Step 1: Write the failing native identity expectations by inspection**

```text
Expected failures before editing:
- Info.plist still says eqMac in the Apple Events description and uses update.eqmac.app
- Constants.swift still trusts eqmac.app and bitgapp GitHub URLs
- project.pbxproj still exposes eqMac.app, com.bitgapp.eqmac, and eqMac entitlements names
- driver project still builds eqMac.driver and installs into /Library/Audio/Plug-Ins/HAL/eqMac.driver/
```

- [ ] **Step 2: Rewrite launch-facing plist text and disable misleading live feeds where needed**

```xml
<string>eqMacFree uses AppleEvents to automate parts of the local setup flow.</string>
```

```xml
<string>https://example.invalid/eqmacfree-update.xml</string>
```

```xml
<string>Copyright © 2026 eqMacFree contributors.</string>
```

- [ ] **Step 3: Update native constants away from legacy production services**

```swift
static let DOMAIN = "github.com"
static let WEBSITE_URL = URL(string: "https://github.com/YOUR_USERNAME/eqMacFree")!
static let FAQ_URL = URL(string: "https://github.com/YOUR_USERNAME/eqMacFree#readme")!
static let BUG_REPORT_URL = URL(string: "https://github.com/YOUR_USERNAME/eqMacFree/issues")!
static let UPDATES_FEED = URL(string: "https://example.invalid/eqmacfree-update.xml")!
static let BETA_UPDATES_FEED = URL(string: "https://example.invalid/eqmacfree-beta-update.xml")!
static let OPEN_URL_TRUSTED_DOMAINS: [String] = ["github.com"]
```

- [ ] **Step 4: Update Xcode product identity to an independent launch-safe name**

```pbxproj
PRODUCT_BUNDLE_IDENTIFIER = com.eqmacfree.app;
PRODUCT_NAME = eqMacFree;
```

```pbxproj
path = eqMacFree.app;
```

```xml
BuildableName = "eqMacFree.app"
BlueprintName = "eqMacFree"
```

- [ ] **Step 5: Update driver product identity and install path to match the new app line**

```pbxproj
path = eqMacFree.driver;
PRODUCT_BUNDLE_IDENTIFIER = com.eqmacfree.driver;
```

```sh
sudo -A rm -rf /Library/Audio/Plug-Ins/HAL/eqMacFree.driver/
```

- [ ] **Step 6: Verify legacy eqmac endpoints and bundle IDs are removed from edited native config**

Run: `python3 - <<'PY'
from pathlib import Path
files = [
  'native/app/Supporting Files/Info.plist',
  'native/app/Source/Constants.swift',
  'native/app/eqMac.xcodeproj/project.pbxproj',
  'native/app/eqMac.xcodeproj/xcshareddata/xcschemes/eqMac.xcscheme',
  'native/driver/Supporting Files/Info.plist',
  'native/driver/Driver.xcodeproj/project.pbxproj'
]
for f in files:
    text = Path(f).read_text()
    print(f, 'eqmac.app' in text, 'com.bitgapp.eqmac' in text, 'eqMac.driver' in text)
PY`
Expected: edited launch-config files no longer point at `eqmac.app`, `com.bitgapp.eqmac`, or old driver install naming except in untouched historical/internal areas that remain intentionally deferred.

### Task 4: Add feature inventory and post-launch backlog docs

**Files:**
- Create: `docs/roadmap/phase-1-feature-inventory.md`
- Create: `docs/roadmap/lock-feature-backlog.md`
- Modify: `README.md`

- [ ] **Step 1: Write the failing documentation expectations by inspection**

```text
Expected failures before editing:
- No docs/roadmap directory exists
- No standalone inventory file classifies available-now / lock-candidate / missing-reimplementation
- No prioritized backlog exists for post-launch AI implementation work
```

- [ ] **Step 2: Create the concrete feature inventory document**

```md
# eqMacFree Phase 1 Feature Inventory

## available-now
- System audio processing
- Volume booster
- HDMI volume support
- Volume balance
- Basic EQ
- Advanced EQ

## lock-candidate
- Shared Lock badge surfaces
- UI copy that still references unavailable advanced feature tiers
- Visibility surfaces that can later expose reimplemented features

## missing-reimplementation
- Expert EQ
- Spectrum Analyzer
- AudioUnit Hosting
- Spatial Audio
- Volume Mixer
```

- [ ] **Step 3: Create the prioritized lock-feature backlog**

```md
# eqMacFree Lock Feature Backlog

1. Expert EQ — highest value, directly adjacent to existing EQ architecture
2. Spectrum Analyzer — high user visibility, moderate DSP/UI complexity
3. Volume Mixer — high value, higher native/system integration risk
4. AudioUnit Hosting — high complexity, plugin-hosting risk
5. Spatial Audio — advanced DSP research item
```

- [ ] **Step 4: Link README to the new inventory and backlog docs**

```md
- [Phase 1 feature inventory](docs/roadmap/phase-1-feature-inventory.md)
- [Lock feature backlog](docs/roadmap/lock-feature-backlog.md)
```

- [ ] **Step 5: Verify the roadmap docs exist and match the three-bucket model**

Run: `python3 - <<'PY'
from pathlib import Path
for f in ['docs/roadmap/phase-1-feature-inventory.md', 'docs/roadmap/lock-feature-backlog.md']:
    text = Path(f).read_text()
    print(f, all(k in text for k in ['available', 'lock', 'reimplementation']))
PY`
Expected: both roadmap files exist and the inventory includes the bucket model from the spec.

### Task 5: Verify the Phase 1 launch diff

**Files:**
- Modify: `docs/superpowers/plans/2026-04-16-eqmac-free-phase-1-repo-launch.md`
- Reference: all files touched in Tasks 1-4

- [ ] **Step 1: Run TypeScript/Angular diagnostics over edited UI files**

Run: `lsp_diagnostics` on `ui/src/app`, `modules/components/src`, and `ui/angular.json`
Expected: no new errors in edited TypeScript/HTML files.

- [ ] **Step 2: Run package metadata and file-pattern verification**

Run: `node -e "const p=require('./package.json'); console.log(p.name, p.repository.url, p.bugs.url)"`
Expected: prints eqMacFree repo metadata without parse errors.

- [ ] **Step 3: Run the repo lint command if available for the edited JS/TS surfaces**

Run: `yarn lint`
Expected: exit code 0, or if unrelated pre-existing failures exist, document which are pre-existing and keep the edited files clean.

- [ ] **Step 4: Run a targeted UI build check**

Run: `yarn --cwd ui build`
Expected: Angular build completes successfully or fails only on pre-existing unrelated issues that are documented immediately.

- [ ] **Step 5: Run a launch-surface grep to ensure primary branding was replaced**

Run: `python3 - <<'PY'
from pathlib import Path
targets = [
  'README.md','package.json','CONTRIBUTING.md','SECURITY.md','CODE_OF_CONDUCT.md',
  '.github/ISSUE_TEMPLATE/bug-report.md','ui/src/index.html',
  'ui/src/app/app.component.ts','ui/src/app/sections/header/header.component.html',
  'ui/src/app/sections/header/header.component.ts','ui/src/app/sections/settings/settings.component.ts',
  'modules/components/src/components/pro/pro.component.ts','native/app/Supporting Files/Info.plist',
  'native/app/Source/Constants.swift','native/driver/Supporting Files/Info.plist'
]
for f in targets:
    text = Path(f).read_text()
    print(f, 'eqMacFree' in text, 'Pro' in text)
PY`
Expected: touched public-facing files contain `eqMacFree`; `Pro` remains only where intentionally deferred for later internal cleanup.

- [ ] **Step 6: Summarize manual repo launch follow-up**

```text
After verification, create the new GitHub repo under the user's account, update the local git remote to that repo, push the Phase 1 branch when requested, and then begin feature-by-feature lock reimplementation planning.
```
