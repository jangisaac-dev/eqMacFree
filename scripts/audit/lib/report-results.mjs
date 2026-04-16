function formatResultLine (result) {
  const details = [
    `${result.severity.toUpperCase()}: ${result.ruleId} in ${result.filePath} -> found ${result.match}`
  ]

  if (result.ruleWhy) {
    details.push(`why: ${result.ruleWhy}`)
  }

  if (result.expectedFix) {
    details.push(`expected fix: ${result.expectedFix}`)
  }

  return details.join(' | ')
}

export function reportResults (results) {
  const sortedResults = [...results].sort((left, right) => {
    if (left.severity === right.severity) {
      if (left.ruleId === right.ruleId) return left.filePath.localeCompare(right.filePath)
      return left.ruleId.localeCompare(right.ruleId)
    }

    if (left.severity === 'hard') return -1
    if (right.severity === 'hard') return 1
    return left.severity.localeCompare(right.severity)
  })

  if (sortedResults.length === 0) {
    console.log('eqMacFree boundary audit passed')
    return 0
  }

  let hardFailures = 0
  let warnings = 0

  for (const result of sortedResults) {
    console.log(formatResultLine(result))
    if (result.severity === 'hard') {
      hardFailures += 1
    } else if (result.severity === 'warning') {
      warnings += 1
    }
  }

  console.log(`eqMacFree boundary audit completed with ${hardFailures} hard failure(s) and ${warnings} warning(s)`)

  return hardFailures > 0 ? 1 : 0
}
