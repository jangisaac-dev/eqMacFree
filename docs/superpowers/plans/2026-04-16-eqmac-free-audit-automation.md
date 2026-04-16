# eqMacFree Audit Automation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a small local audit system that protects eqMacFree’s public product boundary by scanning launch-critical files for legacy infrastructure references, misleading feature language, and documentation drift.

**Architecture:** The first version uses plain JSON/Markdown config plus a single Node-based audit entrypoint so contributors can review and extend the rules without learning a custom framework. The audit is intentionally launch-surface scoped: it loads one manifest, expands a small supported set of path patterns using only built-in Node filesystem APIs, reports hard failures vs warnings vs allowed exceptions, and exposes one package script for repeatable local verification.

**Tech Stack:** Node.js, package.json scripts, JSON manifest/rule files, Markdown docs, existing repository file layout

---

## File Structure

- Create: `scripts/audit/run-boundary-audit.mjs` — executable audit command that loads rules, scans files, prints categorized results, and exits non-zero on hard failures.
- Create: `scripts/audit/lib/load-manifest.mjs` — manifest loader plus lightweight target-expansion helper built on Node filesystem APIs.
- Create: `scripts/audit/lib/evaluate-rules.mjs` — rule evaluation layer for forbidden patterns, restricted wording, alignment checks, and allowed exceptions.
- Create: `scripts/audit/lib/report-results.mjs` — stable output formatter for pass/fail/warning reporting.
- Create: `config/eqmacfree-boundary-audit.json` — explicit launch-critical target list, forbidden patterns, restricted wording, allowed-exception scopes, and alignment expectations.
- Create: `docs/guardrails/feature-capability-audit.md` — contributor-facing checklist and workflow doc.
- Create: `scripts/audit/fixtures/good/README.md` — known-good fixture for smoke verification.
- Create: `scripts/audit/fixtures/hard-fail/ui-constants.ts` — known-bad fixture proving hard failure behavior.
- Create: `scripts/audit/fixtures/allowed-exception/README.md` — fixture proving allowed historical references stay permitted.
- Modify: `package.json` — add `audit:boundary` script.
- Modify: `README.md` — document the audit command in the repo workflow.
- Modify: `CONTRIBUTING.md` — add contributor instruction for boundary audits when touching launch-critical surfaces.

### Task 1: Define the audit surface and command entrypoint

**Files:**
- Create: `config/eqmacfree-boundary-audit.json`
- Modify: `package.json`

- [ ] **Step 1: Write the failing manifest and script expectation check**

Create a temporary verification command by reading `package.json` and checking for the missing audit script before implementation.

Run:

```bash
node -e "const pkg=require('./package.json'); if (pkg.scripts['audit:boundary']) { process.exit(1) } console.log('missing audit:boundary as expected')"
```

Expected: PASS with `missing audit:boundary as expected`

- [ ] **Step 2: Add the boundary audit manifest**

Create `config/eqmacfree-boundary-audit.json` with the first explicit launch-critical scope and rule set.

```json
{
  "targets": [
    "README.md",
    "package.json",
    "CONTRIBUTING.md",
    "docs/roadmap/*.md",
    ".github/ISSUE_TEMPLATE/*.md",
    "ui/src/**/*.ts",
    "ui/src/**/*.html",
    "ui/angular.json",
    "native/app/Source/Constants.swift",
    "native/app/Supporting Files/Info.plist",
    "native/driver/Supporting Files/Info.plist",
    "native/app/eqMac.xcodeproj/xcshareddata/xcschemes/*.xcscheme",
    "native/driver/Driver.xcodeproj/xcshareddata/xcschemes/*.xcscheme"
  ],
  "forbiddenPatterns": [
    {
      "id": "legacy-eqmac-domain",
      "severity": "hard",
      "patterns": ["eqmac.app", "update.eqmac.app", "ui-v3.eqmac.app"]
    },
    {
      "id": "legacy-github-repo",
      "severity": "hard",
      "patterns": ["bitgapp/eqMac"]
    },
    {
      "id": "legacy-bundle-ids",
      "severity": "hard",
      "patterns": ["com.bitgapp.eqmac", "com.bitgapp.eqmac.driver"]
    }
  ],
  "restrictedWording": [
    {
      "id": "legacy-paid-language",
      "severity": "hard",
      "patterns": ["Pro", "Premium", "Upgrade", "promotion"],
      "allowedIn": [
        "README.md",
        "docs/superpowers/specs/*.md",
        "docs/superpowers/plans/*.md",
        "docs/guardrails/*.md"
      ]
    }
  ],
  "alignmentChecks": [
    {
      "id": "readme-feature-buckets",
      "severity": "warning",
      "file": "README.md",
      "requiredSnippets": ["### Available now", "### Lock candidates", "### Missing reimplementation"]
    },
    {
      "id": "roadmap-reimplementation-language",
      "severity": "warning",
      "file": "docs/roadmap/lock-feature-backlog.md",
      "requiredSnippets": ["reimplementation", "not a checklist for unlocking hidden code"]
    }
  ]
}
```

- [ ] **Step 3: Wire the package script**

Update `package.json` scripts to expose the audit command without replacing the current lint entrypoint.

```json
{
  "scripts": {
    "lint": "npx eslint .",
    "audit:boundary": "node scripts/audit/run-boundary-audit.mjs"
  }
}
```

- [ ] **Step 4: Verify the manifest and script wiring exists**

Run:

```bash
node -e "const pkg=require('./package.json'); if (pkg.scripts['audit:boundary'] !== 'node scripts/audit/run-boundary-audit.mjs') throw new Error('audit script missing'); console.log('audit script wired')"
```

Expected: PASS with `audit script wired`

- [ ] **Step 5: Commit**

```bash
git add package.json config/eqmacfree-boundary-audit.json
git commit -m "Add eqMacFree boundary audit manifest"
```

### Task 2: Implement the audit runner and rule evaluation

**Files:**
- Create: `scripts/audit/run-boundary-audit.mjs`
- Create: `scripts/audit/lib/load-manifest.mjs`
- Create: `scripts/audit/lib/evaluate-rules.mjs`
- Create: `scripts/audit/lib/report-results.mjs`

- [ ] **Step 1: Write the failing command check**

Run the package script before the runner exists.

Run:

```bash
yarn audit:boundary
```

Expected: FAIL with a Node file-not-found error for `scripts/audit/run-boundary-audit.mjs`

- [ ] **Step 2: Add the manifest loader**

Create `scripts/audit/lib/load-manifest.mjs`.

```js
import fs from 'fs'
import path from 'path'

export function loadManifest (rootDir, manifestPath) {
  const absolutePath = path.resolve(rootDir, manifestPath)
  const raw = fs.readFileSync(absolutePath, 'utf8')
  return JSON.parse(raw)
}
```

- [ ] **Step 3: Add rule evaluation helpers**

Create `scripts/audit/lib/evaluate-rules.mjs`.

```js
export function evaluateForbiddenPatterns ({ filePath, content, rules }) {
  const failures = []

  for (const rule of rules) {
    for (const pattern of rule.patterns) {
      if (content.includes(pattern)) {
        failures.push({
          severity: rule.severity,
          type: 'forbidden-pattern',
          ruleId: rule.id,
          filePath,
          match: pattern
        })
      }
    }
  }

  return failures
}

export function evaluateRestrictedWording ({ filePath, content, rules, isAllowedException }) {
  const findings = []

  for (const rule of rules) {
    for (const pattern of rule.patterns) {
      if (!content.includes(pattern)) continue

      if (isAllowedException({ filePath, rule })) {
        continue
      }

      findings.push({
        severity: rule.severity,
        type: 'restricted-wording',
        ruleId: rule.id,
        filePath,
        match: pattern
      })
    }
  }

  return findings
}

export function evaluateAlignmentChecks ({ manifest, fileMap }) {
  const warnings = []

  for (const rule of manifest.alignmentChecks) {
    const content = fileMap.get(rule.file) ?? ''
    const missing = rule.requiredSnippets.filter(snippet => !content.includes(snippet))

    if (missing.length > 0) {
      warnings.push({
        severity: rule.severity,
        type: 'alignment-check',
        ruleId: rule.id,
        filePath: rule.file,
        match: missing.join(', ')
      })
    }
  }

  return warnings
}
```

- [ ] **Step 4: Add result reporting**

Create `scripts/audit/lib/report-results.mjs`.

```js
export function reportResults (results) {
  if (results.length === 0) {
    console.log('eqMacFree boundary audit passed')
    return 0
  }

  let hardFailures = 0

  for (const result of results) {
    console.log(`${result.severity.toUpperCase()}: ${result.ruleId} in ${result.filePath} -> found ${result.match}`)
    if (result.severity === 'hard') hardFailures += 1
  }

  return hardFailures > 0 ? 1 : 0
}
```

- [ ] **Step 5: Add the audit entrypoint**

Create `scripts/audit/run-boundary-audit.mjs`.

```js
import fs from 'fs'
import path from 'path'
import { loadManifest } from './lib/load-manifest.mjs'
import { evaluateForbiddenPatterns, evaluateRestrictedWording, evaluateAlignmentChecks } from './lib/evaluate-rules.mjs'
import { reportResults } from './lib/report-results.mjs'

const rootDir = process.cwd()
const manifest = loadManifest(rootDir, 'config/eqmacfree-boundary-audit.json')
const fileMap = new Map()
const results = []

function walkFiles (dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true })
  const files = []

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name)
    if (entry.isDirectory()) {
      files.push(...walkFiles(fullPath))
    } else {
      files.push(fullPath)
    }
  }

  return files
}

function resolveTarget (baseDir, target) {
  if (!target.includes('*')) {
    return fs.existsSync(path.resolve(baseDir, target)) ? [target] : []
  }

  const allFiles = walkFiles(baseDir)
    .map(file => path.relative(baseDir, file))
    .map(file => file.split(path.sep).join('/'))

  if (target.endsWith('/**/*.ts')) {
    const prefix = target.replace('/**/*.ts', '/')
    return allFiles.filter(file => file.startsWith(prefix) && file.endsWith('.ts'))
  }

  if (target.endsWith('/**/*.html')) {
    const prefix = target.replace('/**/*.html', '/')
    return allFiles.filter(file => file.startsWith(prefix) && file.endsWith('.html'))
  }

  if (target.endsWith('/*.md')) {
    const prefix = target.replace('/*.md', '/')
    return allFiles.filter(file => file.startsWith(prefix) && file.endsWith('.md'))
  }

  if (target.endsWith('/*.xcscheme')) {
    const prefix = target.replace('/*.xcscheme', '/')
    return allFiles.filter(file => file.startsWith(prefix) && file.endsWith('.xcscheme'))
  }

  throw new Error(`Unsupported target pattern: ${target}`)
}

function isAllowedException ({ filePath, rule }) {
  return rule.allowedIn.some(pattern => {
    if (!pattern.includes('*')) return filePath === pattern
    if (pattern.endsWith('/*.md')) {
      const prefix = pattern.replace('/*.md', '/')
      return filePath.startsWith(prefix) && filePath.endsWith('.md')
    }
    return false
  })
}

for (const target of manifest.targets) {
  for (const match of resolveTarget(rootDir, target)) {
    const absolutePath = path.resolve(rootDir, match)
    const content = fs.readFileSync(absolutePath, 'utf8')
    fileMap.set(match, content)

    results.push(...evaluateForbiddenPatterns({
      filePath: match,
      content,
      rules: manifest.forbiddenPatterns
    }))

    results.push(...evaluateRestrictedWording({
      filePath: match,
      content,
      rules: manifest.restrictedWording,
      isAllowedException
    }))
  }
}

results.push(...evaluateAlignmentChecks({ manifest, fileMap }))

process.exit(reportResults(results))
```

- [ ] **Step 6: Run the command to verify the current repo passes or produces only the expected warning class**

Run:

```bash
yarn audit:boundary
```

Expected: PASS with `eqMacFree boundary audit passed`, or only documented warning output if the alignment checks intentionally report warnings without a non-zero exit code

- [ ] **Step 7: Commit**

```bash
git add scripts/audit/run-boundary-audit.mjs scripts/audit/lib/load-manifest.mjs scripts/audit/lib/evaluate-rules.mjs scripts/audit/lib/report-results.mjs
git commit -m "Add eqMacFree boundary audit runner"
```

### Task 3: Add fixture-backed proof for hard-fail and allowed-exception behavior

**Files:**
- Create: `scripts/audit/fixtures/good/README.md`
- Create: `scripts/audit/fixtures/hard-fail/ui-constants.ts`
- Create: `scripts/audit/fixtures/allowed-exception/README.md`
- Modify: `scripts/audit/run-boundary-audit.mjs`

- [ ] **Step 1: Write the failing verification command for fixture mode**

Attempt to run the audit command against a fixture override before fixture support exists.

Run:

```bash
node scripts/audit/run-boundary-audit.mjs --manifest config/eqmacfree-boundary-audit.json --target-root scripts/audit/fixtures/hard-fail
```

Expected: FAIL because the runner does not yet support `--target-root`

- [ ] **Step 2: Add fixture files**

Create the three fixture files.

`scripts/audit/fixtures/good/README.md`

```md
# eqMacFree

### Available now
- System audio processing

### Lock candidates
- Lock-state UX cleanup

### Missing reimplementation
- Volume mixer
```

`scripts/audit/fixtures/hard-fail/ui-constants.ts`

```ts
export const WEBSITE_URL = 'https://eqmac.app'
```

`scripts/audit/fixtures/allowed-exception/README.md`

```md
# Historical note

This project does not bypass Pro licensing or private-repo functionality.
```

- [ ] **Step 3: Extend the runner with fixture-root support**

Update `scripts/audit/run-boundary-audit.mjs` so it accepts an optional `--target-root` directory and resolves glob matches from that directory instead of the repo root when present.

```js
const targetRootFlagIndex = process.argv.indexOf('--target-root')
const targetRoot = targetRootFlagIndex >= 0
  ? path.resolve(rootDir, process.argv[targetRootFlagIndex + 1])
  : rootDir

for (const target of manifest.targets) {
  for (const match of resolveTarget(targetRoot, target)) {
    const absolutePath = path.resolve(targetRoot, match)
    const content = fs.readFileSync(absolutePath, 'utf8')
    fileMap.set(match, content)
    // existing evaluation logic continues here
  }
}
```

- [ ] **Step 4: Narrow fixture manifests so the examples stay deterministic**

Create fixture-specific manifest files that exercise only the relevant target file for each proof case.

`scripts/audit/fixtures/hard-fail/manifest.json`

```json
{
  "targets": ["ui-constants.ts"],
  "forbiddenPatterns": [
    {
      "id": "legacy-eqmac-domain",
      "severity": "hard",
      "patterns": ["eqmac.app"]
    }
  ],
  "restrictedWording": [],
  "alignmentChecks": []
}
```

`scripts/audit/fixtures/allowed-exception/manifest.json`

```json
{
  "targets": ["README.md"],
  "forbiddenPatterns": [],
  "restrictedWording": [
    {
      "id": "legacy-paid-language",
      "severity": "hard",
      "patterns": ["Pro"],
      "allowedIn": ["README.md"]
    }
  ],
  "alignmentChecks": []
}
```

`scripts/audit/fixtures/good/manifest.json`

```json
{
  "targets": ["README.md"],
  "forbiddenPatterns": [],
  "restrictedWording": [],
  "alignmentChecks": [
    {
      "id": "readme-feature-buckets",
      "severity": "warning",
      "file": "README.md",
      "requiredSnippets": ["### Available now", "### Lock candidates", "### Missing reimplementation"]
    }
  ]
}
```

- [ ] **Step 5: Add `--manifest` support to the runner**

Update `scripts/audit/run-boundary-audit.mjs` so `--manifest` overrides the default manifest path.

```js
const manifestFlagIndex = process.argv.indexOf('--manifest')
const manifestPath = manifestFlagIndex >= 0
  ? process.argv[manifestFlagIndex + 1]
  : 'config/eqmacfree-boundary-audit.json'

const manifest = loadManifest(rootDir, manifestPath)
```

- [ ] **Step 6: Verify the hard-fail fixture**

Run:

```bash
node scripts/audit/run-boundary-audit.mjs --manifest scripts/audit/fixtures/hard-fail/manifest.json --target-root scripts/audit/fixtures/hard-fail
```

Expected: FAIL with output containing `legacy-eqmac-domain` and `eqmac.app`

- [ ] **Step 7: Verify the allowed-exception fixture**

Run:

```bash
node scripts/audit/run-boundary-audit.mjs --manifest scripts/audit/fixtures/allowed-exception/manifest.json --target-root scripts/audit/fixtures/allowed-exception
```

Expected: PASS without treating the historical `Pro` wording as a hard failure

- [ ] **Step 8: Verify the known-good fixture**

Run:

```bash
node scripts/audit/run-boundary-audit.mjs --manifest scripts/audit/fixtures/good/manifest.json --target-root scripts/audit/fixtures/good
```

Expected: PASS with `eqMacFree boundary audit passed`

- [ ] **Step 9: Commit**

```bash
git add scripts/audit/run-boundary-audit.mjs scripts/audit/fixtures/good/README.md scripts/audit/fixtures/good/manifest.json scripts/audit/fixtures/hard-fail/ui-constants.ts scripts/audit/fixtures/hard-fail/manifest.json scripts/audit/fixtures/allowed-exception/README.md scripts/audit/fixtures/allowed-exception/manifest.json
git commit -m "Add eqMacFree audit verification fixtures"
```

### Task 4: Document contributor workflow and wire the audit into repo guidance

**Files:**
- Create: `docs/guardrails/feature-capability-audit.md`
- Modify: `README.md`
- Modify: `CONTRIBUTING.md`

- [ ] **Step 1: Write the failing documentation expectation check**

Verify the repo docs do not yet mention the audit command.

Run:

```bash
node -e "const fs=require('fs'); const readme=fs.readFileSync('README.md','utf8'); const contributing=fs.readFileSync('CONTRIBUTING.md','utf8'); if (readme.includes('audit:boundary') || contributing.includes('audit:boundary')) process.exit(1); console.log('audit docs missing as expected')"
```

Expected: PASS with `audit docs missing as expected`

- [ ] **Step 2: Add the contributor-facing audit doc**

Create `docs/guardrails/feature-capability-audit.md`.

```md
# eqMacFree Feature Capability Audit

Run `yarn audit:boundary` whenever a change touches launch-critical docs, UI copy, native launch identity, or public support/update routing.

## Human checklist

- Did this change reintroduce a legacy eqMac URL or old GitHub repo reference?
- Does `Lock` still mean planned or unavailable, not purchasable or secretly unlockable?
- Do README and roadmap files still use the same feature buckets?
- Do support and update links still point to public GitHub surfaces or intentionally neutralized endpoints?

## Result types

- Hard fail: fix before merging
- Warning: review wording drift and either fix it or document why it is intentional
- Allowed exception: historical context in approved files such as README or design docs
```

- [ ] **Step 3: Link the audit workflow from the main docs**

Update `README.md` to add a guardrails section near the roadmap links.

```md
## Guardrails

- Run `yarn audit:boundary` before merging launch-surface changes.
- See [`docs/guardrails/feature-capability-audit.md`](docs/guardrails/feature-capability-audit.md) for the release checklist and audit rule intent.
```

Update `CONTRIBUTING.md` to require the audit for launch-surface changes.

```md
If your change touches README, roadmap docs, user-facing UI copy, native launch identity, or support/update routing, run:

    yarn audit:boundary
```

- [ ] **Step 4: Verify the documented workflow**

Run:

```bash
node -e "const fs=require('fs'); const readme=fs.readFileSync('README.md','utf8'); const contributing=fs.readFileSync('CONTRIBUTING.md','utf8'); const auditDoc=fs.readFileSync('docs/guardrails/feature-capability-audit.md','utf8'); if (!readme.includes('audit:boundary')) throw new Error('README missing audit command'); if (!contributing.includes('audit:boundary')) throw new Error('CONTRIBUTING missing audit command'); if (!auditDoc.includes('Hard fail')) throw new Error('audit doc missing result types'); console.log('audit docs wired')"
```

Expected: PASS with `audit docs wired`

- [ ] **Step 5: Run the full feature verification sequence**

Run:

```bash
yarn audit:boundary && node scripts/audit/run-boundary-audit.mjs --manifest scripts/audit/fixtures/hard-fail/manifest.json --target-root scripts/audit/fixtures/hard-fail; test $? -ne 0 && node scripts/audit/run-boundary-audit.mjs --manifest scripts/audit/fixtures/allowed-exception/manifest.json --target-root scripts/audit/fixtures/allowed-exception && node scripts/audit/run-boundary-audit.mjs --manifest scripts/audit/fixtures/good/manifest.json --target-root scripts/audit/fixtures/good
```

Expected:
- repo audit returns success
- hard-fail fixture returns non-zero
- allowed-exception fixture returns success
- good fixture returns success

- [ ] **Step 6: Commit**

```bash
git add README.md CONTRIBUTING.md docs/guardrails/feature-capability-audit.md
git commit -m "Document eqMacFree boundary audit workflow"
```
