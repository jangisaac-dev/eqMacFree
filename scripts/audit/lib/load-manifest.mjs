import fs from 'fs'
import path from 'path'

function normalizePath (value) {
  return value.split(path.sep).join('/')
}

function walkFiles (dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true })
  const files = []

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name)
    if (entry.isDirectory()) {
      files.push(...walkFiles(fullPath))
      continue
    }

    files.push(fullPath)
  }

  return files
}

function resolveGlobTarget (rootDir, target) {
  const normalizedTarget = normalizePath(target)
  const allFiles = walkFiles(rootDir).map(filePath => normalizePath(path.relative(rootDir, filePath)))

  if (normalizedTarget.endsWith('/**/*.ts')) {
    const prefix = normalizedTarget.slice(0, -('/**/*.ts'.length))
    return allFiles.filter(filePath => filePath.startsWith(`${prefix}/`) && filePath.endsWith('.ts'))
  }

  if (normalizedTarget.endsWith('/**/*.html')) {
    const prefix = normalizedTarget.slice(0, -('/**/*.html'.length))
    return allFiles.filter(filePath => filePath.startsWith(`${prefix}/`) && filePath.endsWith('.html'))
  }

  if (normalizedTarget.endsWith('/*.md')) {
    const prefix = normalizedTarget.slice(0, -('/*.md'.length))
    return allFiles.filter(filePath => filePath.startsWith(`${prefix}/`) && filePath.endsWith('.md'))
  }

  if (normalizedTarget.endsWith('/*.xcscheme')) {
    const prefix = normalizedTarget.slice(0, -('/*.xcscheme'.length))
    return allFiles.filter(filePath => filePath.startsWith(`${prefix}/`) && filePath.endsWith('.xcscheme'))
  }

  throw new Error(`Unsupported target pattern: ${target}`)
}

export function loadManifest (rootDir, manifestPath) {
  const absolutePath = path.resolve(rootDir, manifestPath)
  const raw = fs.readFileSync(absolutePath, 'utf8')
  const manifest = JSON.parse(raw)

  return manifest
}

export function expandManifestTargets (rootDir, targets) {
  const expanded = []
  const seen = new Set()

  for (const target of targets) {
    const normalizedTarget = normalizePath(target)
    const absoluteTarget = path.resolve(rootDir, target)
    const matches = normalizedTarget.includes('*')
      ? resolveGlobTarget(rootDir, normalizedTarget)
      : (fs.existsSync(absoluteTarget) ? [normalizedTarget] : (() => { throw new Error(`Manifest target not found: ${normalizedTarget}`) })())

    for (const match of matches) {
      if (seen.has(match)) continue
      seen.add(match)
      expanded.push(match)
    }
  }

  return expanded
}
