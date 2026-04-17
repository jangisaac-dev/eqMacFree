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
DERIVED_DATA="$ROOT_DIR/build-release"
APP_BUNDLE="$DERIVED_DATA/Build/Products/Release/eqMacFree.app"
ZIP_NAME="eqMacFree-${VERSION}.zip"
ZIP_PATH="$ARCHIVE_DIR/$ZIP_NAME"
APPCAST_PATH="$ARCHIVE_DIR/${CHANNEL}.xml"
DOWNLOAD_PREFIX="https://github.com/${OWNER}/${REPO}/releases/download/${TAG}/"
RELEASE_NOTES_PREFIX="https://github.com/${OWNER}/${REPO}/releases/tag/${TAG}"

echo "Preparing version metadata for ${VERSION} (${BUILD_NUMBER})"
node scripts/release/prepare-release.mjs --version "$VERSION" --build "$BUILD_NUMBER" --channel "$CHANNEL" --owner "$OWNER" --repo "$REPO" --tagPrefix "$TAG_PREFIX" >/dev/null

rm -rf "$ARCHIVE_DIR" "$DERIVED_DATA"
mkdir -p "$ARCHIVE_DIR"

echo "Building UI bundle"
(cd ui && npm run build >/dev/null)

echo "Building signed Release app"
xcodebuild \
  -workspace native/eqMac.xcworkspace \
  -scheme eqMac \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA" \
  build

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "Release app bundle not found at $APP_BUNDLE" >&2
  exit 1
fi

echo "Packaging app archive"
ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"

echo "Generating signed appcast"
(
  cd "$ARCHIVE_DIR"
  "$ROOT_DIR/native/Pods/Sparkle/bin/generate_appcast" \
    -o "$(basename "$APPCAST_PATH")" \
    --download-url-prefix "$DOWNLOAD_PREFIX" \
    --release-notes-url-prefix "$RELEASE_NOTES_PREFIX" \
    .
)

cp "$APPCAST_PATH" "$ROOT_DIR/docs/appcast/${CHANNEL}.xml"

echo
echo "Built distribution artifacts:"
echo "  App archive: $ZIP_PATH"
echo "  Appcast: $APPCAST_PATH"
