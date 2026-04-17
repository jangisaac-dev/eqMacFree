#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="eqMacFree"
WORKSPACE="native/eqMac.xcworkspace"
SCHEME="eqMac"
CONFIGURATION="Debug"
DRIVER_PROJECT="native/driver/Driver.xcodeproj"
DRIVER_SCHEME="Driver - Debug"
SYSTEM_DRIVER_DIR="/Library/Audio/Plug-Ins/HAL"
SYSTEM_DRIVER_BUNDLE="$SYSTEM_DRIVER_DIR/$APP_NAME.driver"
FORCE_DRIVER_INSTALL=0

case "$MODE" in
  --install-driver|install-driver|--reinstall-driver|reinstall-driver)
    FORCE_DRIVER_INSTALL=1
    MODE="run"
    ;;
esac

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="$ROOT_DIR/build"
DRIVER_DERIVED_DATA="$ROOT_DIR/build-driver"
DRIVER_BUNDLE="$DRIVER_DERIVED_DATA/Build/Products/$CONFIGURATION/$APP_NAME.driver"
APP_BUNDLE="$DERIVED_DATA/Build/Products/$CONFIGURATION/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"

build_driver() {
  xcodebuild \
    -project "$DRIVER_PROJECT" \
    -scheme "$DRIVER_SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DRIVER_DERIVED_DATA" \
    build
}

install_driver() {
  if [[ ! -d "$DRIVER_BUNDLE" ]]; then
    echo "Driver bundle missing at $DRIVER_BUNDLE" >&2
    return 1
  fi

  if [[ "$FORCE_DRIVER_INSTALL" -eq 0 && -d "$SYSTEM_DRIVER_BUNDLE" ]]; then
    echo "Driver already installed at $SYSTEM_DRIVER_BUNDLE"
    return 0
  fi

  if sudo -n true >/dev/null 2>&1; then
    sudo rm -rf "$SYSTEM_DRIVER_BUNDLE"
    sudo cp -R "$DRIVER_BUNDLE" "$SYSTEM_DRIVER_DIR/"
    sudo launchctl kickstart -k system/com.apple.audio.coreaudiod
    return 0
  fi

  if [[ -x "$HOME/askpass.sh" ]]; then
    export SUDO_ASKPASS="$HOME/askpass.sh"
    sudo -A rm -rf "$SYSTEM_DRIVER_BUNDLE"
    sudo -A cp -R "$DRIVER_BUNDLE" "$SYSTEM_DRIVER_DIR/"
    sudo -A launchctl kickstart -k system/com.apple.audio.coreaudiod
    return 0
  fi

  echo "Driver build succeeded, but installation requires passwordless sudo or \$HOME/askpass.sh." >&2
  return 1
}

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

build_driver
install_driver

xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  build

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|install-driver|reinstall-driver|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
