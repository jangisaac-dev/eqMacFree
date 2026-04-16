import fs from 'fs'
import path from 'path'
import { loadManifest, expandManifestTargets } from './lib/load-manifest.mjs'
import { evaluateForbiddenPatterns, evaluateRestrictedWording, evaluateAlignmentChecks } from './lib/evaluate-rules.mjs'
import { reportResults } from './lib/report-results.mjs'

const rootDir = process.cwd()
const manifestFlagIndex = process.argv.indexOf('--manifest')
const manifestPath = manifestFlagIndex >= 0
  ? process.argv[manifestFlagIndex + 1]
  : 'config/eqmacfree-boundary-audit.json'
const targetRootFlagIndex = process.argv.indexOf('--target-root')
const targetRoot = targetRootFlagIndex >= 0
  ? path.resolve(rootDir, process.argv[targetRootFlagIndex + 1])
  : rootDir
const manifest = loadManifest(rootDir, manifestPath)
const fileMap = new Map()
const results = []

for (const relativePath of expandManifestTargets(targetRoot, manifest.targets)) {
  const absolutePath = path.resolve(targetRoot, relativePath)
  const content = fs.readFileSync(absolutePath, 'utf8')
  fileMap.set(relativePath, content)

  results.push(...evaluateForbiddenPatterns({
    filePath: relativePath,
    content,
    rules: manifest.forbiddenPatterns ?? []
  }))

  results.push(...evaluateRestrictedWording({
    filePath: relativePath,
    content,
    rules: manifest.restrictedWording ?? []
  }))
}

results.push(...evaluateAlignmentChecks({ manifest, fileMap }))

process.exit(reportResults(results))
