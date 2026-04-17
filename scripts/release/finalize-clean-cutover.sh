#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

VERSION="${VERSION:?Set VERSION, for example VERSION=1.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:?Set BUILD_NUMBER, for example BUILD_NUMBER=10100}"
OWNER="${OWNER:-jangisaac-dev}"
REPO="${REPO:-eqMacFree}"
TARGET_BRANCH="${TARGET_BRANCH:-main}"
TAG_PREFIX="${TAG_PREFIX:-eqmacfree-v}"
TARGET_TAG="${TARGET_TAG:-${TAG_PREFIX}${VERSION}}"
REMOTE_URL="${REMOTE_URL:-https://github.com/${OWNER}/${REPO}.git}"
TEMP_BRANCH="cutover/${TARGET_TAG}"
BACKUP_BRANCH="archive/pre-cutover-$(date +%Y%m%d%H%M%S)"
CURRENT_BRANCH="$(git branch --show-current)"

if [[ -n "$(git status --short)" ]]; then
  echo "Working tree must be clean before final cutover." >&2
  exit 1
fi

echo "Preparing final clean-history cutover for ${TARGET_TAG}"
echo "Remote: ${REMOTE_URL}"
echo "Backup branch: ${BACKUP_BRANCH}"

git branch "$BACKUP_BRANCH"

if git rev-parse --verify "$TEMP_BRANCH" >/dev/null 2>&1; then
  git branch -D "$TEMP_BRANCH"
fi

git checkout --orphan "$TEMP_BRANCH"
git add -A
git commit -m "Release ${VERSION} (${BUILD_NUMBER})"

if git rev-parse --verify "$TARGET_TAG" >/dev/null 2>&1; then
  git tag -d "$TARGET_TAG"
fi
git tag -a "$TARGET_TAG" -m "eqMacFree ${VERSION}"

echo "Deleting GitHub releases except ${TARGET_TAG}"
while read -r tagName; do
  [[ -z "$tagName" ]] && continue
  if [[ "$tagName" != "$TARGET_TAG" ]]; then
    gh release delete "$tagName" -R "${OWNER}/${REPO}" --yes || true
  fi
done < <(gh release list -R "${OWNER}/${REPO}" --limit 100 | awk '{print $3}')

echo "Deleting remote tags except ${TARGET_TAG}"
while read -r remoteTag; do
  [[ -z "$remoteTag" ]] && continue
  shortTag="${remoteTag#refs/tags/}"
  shortTag="${shortTag%\^\{\}}"
  if [[ "$shortTag" != "$TARGET_TAG" ]]; then
    git push "$REMOTE_URL" ":refs/tags/${shortTag}" || true
  fi
done < <(git ls-remote --tags "$REMOTE_URL" | awk '{print $2}' | sort -u)

echo "Force-updating ${TARGET_BRANCH} to single-commit history"
git push "$REMOTE_URL" "HEAD:${TARGET_BRANCH}" --force
git push "$REMOTE_URL" "refs/tags/${TARGET_TAG}" --force

git checkout "$CURRENT_BRANCH"

echo
echo "Cutover complete."
echo "Backup branch retained locally: ${BACKUP_BRANCH}"
echo "Final branch snapshot: ${TEMP_BRANCH}"
echo "Published tag: ${TARGET_TAG}"
