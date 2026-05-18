#!/usr/bin/env bash
set -euo pipefail

APP_NAME="TelegramKeywordNotifier"
BUNDLE_ID="${BUNDLE_ID:-com.example.TelegramKeywordNotifier}"
CONFIGURATION="${CONFIGURATION:-release}"
ARCH="${ARCH:-arm64}"
DIST_DIR="dist"
BUNDLE_DIR="${DIST_DIR}/${APP_NAME}.app"

swift build -c "${CONFIGURATION}" --arch "${ARCH}"

BINARY_CANDIDATES=(
  ".build/${ARCH}-apple-macosx/${CONFIGURATION}/${APP_NAME}"
  ".build/${CONFIGURATION}/${APP_NAME}"
)

BINARY_PATH=""
for candidate in "${BINARY_CANDIDATES[@]}"; do
  if [[ -x "${candidate}" ]]; then
    BINARY_PATH="${candidate}"
    break
  fi
done

if [[ -z "${BINARY_PATH}" ]]; then
  echo "Cannot find built ${APP_NAME} executable." >&2
  exit 1
fi

rm -rf "${BUNDLE_DIR}"
mkdir -p "${BUNDLE_DIR}/Contents/MacOS" "${BUNDLE_DIR}/Contents/Resources"
cp "${BINARY_PATH}" "${BUNDLE_DIR}/Contents/MacOS/${APP_NAME}"

cat > "${BUNDLE_DIR}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>ru</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHumanReadableCopyright</key>
  <string></string>
  <key>NSUserNotificationAlertStyle</key>
  <string>alert</string>
</dict>
</plist>
PLIST

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "${BUNDLE_DIR}"
fi

echo "Created ${BUNDLE_DIR}"
