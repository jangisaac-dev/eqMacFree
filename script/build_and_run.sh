#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="eqMacFree"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="$ROOT_DIR/.build/eqmac-spatial"
DRIVER_DERIVED_DATA_PATH="$ROOT_DIR/.build/eqmac-driver"
APP_BUNDLE="$DERIVED_DATA_PATH/Build/Products/Debug/$APP_NAME.app"
DRIVER_BUNDLE="$DRIVER_DERIVED_DATA_PATH/Build/Products/Debug/$APP_NAME.driver"
SYSTEM_DRIVER_DIR="/Library/Audio/Plug-Ins/HAL"
SYSTEM_DRIVER_BUNDLE="$SYSTEM_DRIVER_DIR/$APP_NAME.driver"
FORCE_DRIVER_INSTALL=0
BUILD_FLAGS=(
  -workspace "$ROOT_DIR/native/eqMac.xcworkspace"
  -scheme eqMac
  -configuration Debug
  -derivedDataPath "$DERIVED_DATA_PATH"
  CODE_SIGNING_ALLOWED=NO
  SWIFT_ENABLE_EXPLICIT_MODULES=NO
  MACOSX_DEPLOYMENT_TARGET=10.15
  build
)
DRIVER_BUILD_FLAGS=(
  -workspace "$ROOT_DIR/native/eqMac.xcworkspace"
  -scheme "Driver - Debug"
  -configuration Debug
  -derivedDataPath "$DRIVER_DERIVED_DATA_PATH"
  MACOSX_DEPLOYMENT_TARGET=10.13
  build
)

case "$MODE" in
  --install-driver|install-driver|--reinstall-driver|reinstall-driver)
    FORCE_DRIVER_INSTALL=1
    MODE="run"
    ;;
esac

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

plist_version() {
  /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$1/Contents/Info.plist" 2>/dev/null || true
}

build_driver() {
  xcodebuild "${DRIVER_BUILD_FLAGS[@]}"
}

build_ui() {
  (
    cd "$ROOT_DIR/ui"
    NODE_OPTIONS=--openssl-legacy-provider npm run build
  )
}

restart_coreaudio() {
  if sudo -n true >/dev/null 2>&1; then
    sudo launchctl kickstart -k system/com.apple.audio.coreaudiod >/dev/null 2>&1 || sudo killall coreaudiod >/dev/null 2>&1 || true
    return 0
  fi

  if [[ -x "$HOME/askpass.sh" ]]; then
    export SUDO_ASKPASS="$HOME/askpass.sh"
    sudo -A launchctl kickstart -k system/com.apple.audio.coreaudiod >/dev/null 2>&1 || sudo -A killall coreaudiod >/dev/null 2>&1 || true
    return 0
  fi

  return 1
}

install_driver() {
  if [[ ! -d "$DRIVER_BUNDLE" ]]; then
    echo "Driver bundle missing at $DRIVER_BUNDLE" >&2
    return 1
  fi

  local built_version installed_version
  built_version="$(plist_version "$DRIVER_BUNDLE")"
  installed_version="$(plist_version "$SYSTEM_DRIVER_BUNDLE")"

  if [[ "$FORCE_DRIVER_INSTALL" -eq 0 && -d "$SYSTEM_DRIVER_BUNDLE" && "$built_version" == "$installed_version" ]]; then
    return 0
  fi

  if sudo -n true >/dev/null 2>&1; then
    sudo rm -rf "$SYSTEM_DRIVER_BUNDLE"
    sudo cp -R "$DRIVER_BUNDLE" "$SYSTEM_DRIVER_DIR/"
    restart_coreaudio
    return 0
  fi

  if [[ -x "$HOME/askpass.sh" ]]; then
    export SUDO_ASKPASS="$HOME/askpass.sh"
    sudo -A rm -rf "$SYSTEM_DRIVER_BUNDLE"
    sudo -A cp -R "$DRIVER_BUNDLE" "$SYSTEM_DRIVER_DIR/"
    restart_coreaudio
    return 0
  fi

  echo "Driver install requires passwordless sudo or \$HOME/askpass.sh" >&2
  return 1
}

build_app() {
  build_ui
  xcodebuild "${BUILD_FLAGS[@]}"
}

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

show_window() {
  /usr/bin/osascript <<APPLESCRIPT
tell application "$APP_NAME"
  activate
  reopen
end tell
APPLESCRIPT
}

case "$MODE" in
  run)
    build_driver
    install_driver
    build_app
    open_app
    sleep 2
    show_window || true
    ;;
  --debug|debug)
    build_driver
    install_driver
    build_app
    lldb -- "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    ;;
  --logs|logs)
    build_driver
    install_driver
    build_app
    open_app
    sleep 2
    show_window || true
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    build_driver
    install_driver
    build_app
    open_app
    sleep 2
    show_window || true
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --verify|verify)
    build_driver
    install_driver
    build_app
    open_app
    sleep 2
    show_window || true
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|install-driver|reinstall-driver|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
