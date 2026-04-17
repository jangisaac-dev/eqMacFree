#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

VERSION="${VERSION:-1.0.1}"
BUILD_NUMBER="${BUILD_NUMBER:-10001}"
CHANNEL="${CHANNEL:-stable}"
OWNER="${OWNER:-jangisaac-dev}"
REPO="${REPO:-eqMacFree}"
TAG_PREFIX="${TAG_PREFIX:-eqmacfree-v}"
TAG="${TAG_PREFIX}${VERSION}"

ARCHIVE_DIR="$ROOT_DIR/release-artifacts/$TAG"
ZIP_PATH="$ARCHIVE_DIR/eqMacFree-${VERSION}.zip"

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "Missing release archive. Run scripts/release/build-distribution.sh first." >&2
  exit 1
fi

if gh release view "$TAG" -R "${OWNER}/${REPO}" >/dev/null 2>&1; then
  gh release upload "$TAG" "$ZIP_PATH" -R "${OWNER}/${REPO}" --clobber
else
  gh release create "$TAG" "$ZIP_PATH" \
    -R "${OWNER}/${REPO}" \
    --title "eqMacFree ${VERSION}" \
    --notes "eqMacFree ${VERSION} (${BUILD_NUMBER})"
fi

echo "Published ${TAG} with asset $(basename "$ZIP_PATH")"
