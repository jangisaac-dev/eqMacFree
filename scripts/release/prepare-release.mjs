#!/usr/bin/env node

import fs from 'node:fs'
import path from 'node:path'

const repoRoot = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..', '..')
const args = parseArgs(process.argv.slice(2))

const version = args.version ?? '1.0.0'
const build = args.build ?? versionToBuild(version)
const channel = args.channel ?? 'stable'
const owner = args.owner ?? 'jangisaac-dev'
const repo = args.repo ?? 'eqMacFree'
const tagPrefix = args.tagPrefix ?? 'eqmacfree-v'

if (!/^\d+\.\d+\.\d+$/.test(version)) {
  throw new Error(`Invalid --version: ${version}`)
}

if (!/^\d+$/.test(build)) {
  throw new Error(`Invalid --build: ${build}`)
}

if (!['stable', 'beta'].includes(channel)) {
  throw new Error(`Invalid --channel: ${channel}`)
}

const tag = `${tagPrefix}${version}`
const releaseUrl = `https://github.com/${owner}/${repo}/releases/tag/${tag}`
const feedPath = path.join(repoRoot, 'docs', 'appcast', `${channel}.xml`)

updateJson(path.join(repoRoot, 'package.json'), data => {
  data.version = version
  return data
})

updateText(path.join(repoRoot, 'native', 'app', 'eqMac.xcodeproj', 'project.pbxproj'), contents => (
  replaceAllVersions(contents, { marketingVersion: version, currentProjectVersion: build })
))

updateText(path.join(repoRoot, 'native', 'driver', 'Driver.xcodeproj', 'project.pbxproj'), contents => (
  replaceAllVersions(contents, { marketingVersion: version, currentProjectVersion: build })
))

fs.mkdirSync(path.dirname(feedPath), { recursive: true })
fs.writeFileSync(feedPath, buildAppcast({
  channel,
  version,
  build,
  releaseUrl,
  pubDate: new Date().toUTCString()
}))

process.stdout.write(
  [
    `Prepared eqMacFree ${version} (${build}) for ${channel}.`,
    `Release tag: ${tag}`,
    `Feed: docs/appcast/${channel}.xml`,
    '',
    'Next steps:',
    `1. git add package.json native/app/eqMac.xcodeproj/project.pbxproj native/driver/Driver.xcodeproj/project.pbxproj docs/appcast/${channel}.xml`,
    `2. git commit -m "release: prepare ${version}"`,
    `3. git tag -a ${tag} -m "eqMacFree ${version}"`,
    `4. publish the GitHub release for ${tag}`
  ].join('\n')
)

function parseArgs (argv) {
  const result = {}
  for (let index = 0; index < argv.length; index += 1) {
    const current = argv[index]
    if (!current.startsWith('--')) continue

    const [ rawKey, inlineValue ] = current.slice(2).split('=')
    const value = inlineValue ?? argv[index + 1]
    result[rawKey] = value
    if (inlineValue == null) index += 1
  }
  return result
}

function versionToBuild (version) {
  const [ major, minor, patch ] = version.split('.').map(Number)
  return `${major}${String(minor).padStart(2, '0')}${String(patch).padStart(2, '0')}`
}

function updateJson (filePath, mutate) {
  const existing = JSON.parse(fs.readFileSync(filePath, 'utf8'))
  const updated = mutate(existing)
  fs.writeFileSync(filePath, `${JSON.stringify(updated, null, 2)}\n`)
}

function updateText (filePath, mutate) {
  const existing = fs.readFileSync(filePath, 'utf8')
  const updated = mutate(existing)
  fs.writeFileSync(filePath, updated)
}

function replaceAllVersions (contents, { marketingVersion, currentProjectVersion }) {
  return contents
    .replace(/MARKETING_VERSION = [^;]+;/g, `MARKETING_VERSION = ${marketingVersion};`)
    .replace(/CURRENT_PROJECT_VERSION = [^;]+;/g, `CURRENT_PROJECT_VERSION = ${currentProjectVersion};`)
}

function buildAppcast ({ channel, version, build, releaseUrl, pubDate }) {
  const title = channel === 'beta' ? `eqMacFree ${version} beta` : `eqMacFree ${version}`
  const description = channel === 'beta'
    ? 'Preview update is available on GitHub Releases.'
    : 'A newer public eqMacFree release is available on GitHub Releases.'

  return `<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0"
  xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"
  xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>eqMacFree ${channel} appcast</title>
    <link>${releaseUrl}</link>
    <description>${description}</description>
    <language>en</language>
    <item>
      <title>${title}</title>
      <link>${releaseUrl}</link>
      <pubDate>${pubDate}</pubDate>
      <sparkle:version>${build}</sparkle:version>
      <sparkle:shortVersionString>${version}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>10.13</sparkle:minimumSystemVersion>
      <description><![CDATA[${description}]]></description>
    </item>
  </channel>
</rss>
`
}
