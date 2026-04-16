function getRuleMatches (content, patterns) {
  const matches = []

  for (const pattern of patterns) {
    if (content.includes(pattern)) {
      matches.push(pattern)
    }
  }

  return matches
}

function escapeRegExp (value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}

function matchesStandaloneText (content, pattern) {
  const expression = new RegExp(`(^|[^A-Za-z0-9_])${escapeRegExp(pattern)}([^A-Za-z0-9_]|$)`)
  return expression.test(content)
}

function getStandaloneRuleMatches (content, patterns) {
  const matches = []

  for (const pattern of patterns) {
    if (matchesStandaloneText(content, pattern)) {
      matches.push(pattern)
    }
  }

  return matches
}

function matchesAllowedScope (filePath, pattern) {
  if (!pattern.includes('*')) {
    return filePath === pattern
  }

  if (pattern.endsWith('/*.md')) {
    const prefix = pattern.slice(0, -('/*.md'.length))
    return filePath.startsWith(`${prefix}/`) && filePath.endsWith('.md')
  }

  if (pattern.endsWith('/**/*.md')) {
    const prefix = pattern.slice(0, -('/**/*.md'.length))
    return filePath.startsWith(`${prefix}/`) && filePath.endsWith('.md')
  }

  return false
}

function isAllowedException (filePath, rule) {
  return (rule.allowedIn ?? []).some(pattern => matchesAllowedScope(filePath, pattern))
}

export function evaluateForbiddenPatterns ({ filePath, content, rules }) {
  const failures = []

  for (const rule of rules) {
    const matches = getRuleMatches(content, rule.patterns)
    for (const match of matches) {
      failures.push({
        severity: rule.severity,
        type: 'forbidden-pattern',
        ruleId: rule.id,
        ruleWhy: rule.why,
        expectedFix: rule.expectedFix,
        filePath,
        match
      })
    }
  }

  return failures
}

export function evaluateRestrictedWording ({ filePath, content, rules }) {
  const findings = []

  for (const rule of rules) {
    if (isAllowedException(filePath, rule)) continue

    const matches = getStandaloneRuleMatches(content, rule.patterns)
    for (const match of matches) {
      findings.push({
        severity: rule.severity,
        type: 'restricted-wording',
        ruleId: rule.id,
        ruleWhy: rule.why,
        expectedFix: rule.expectedFix,
        filePath,
        match
      })
    }
  }

  return findings
}

export function evaluateAlignmentChecks ({ manifest, fileMap }) {
  const warnings = []

  for (const rule of manifest.alignmentChecks ?? []) {
    const content = fileMap.get(rule.file) ?? ''
    const missingSnippets = rule.requiredSnippets.filter(snippet => !content.includes(snippet))

    if (missingSnippets.length > 0) {
      warnings.push({
        severity: rule.severity,
        type: 'alignment-check',
        ruleId: rule.id,
        ruleWhy: rule.why,
        expectedFix: rule.expectedFix,
        filePath: rule.file,
        match: missingSnippets.join(', ')
      })
    }
  }

  return warnings
}
