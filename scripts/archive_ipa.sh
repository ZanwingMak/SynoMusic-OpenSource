#!/usr/bin/env bash
# Release archive + 未签名 IPA 打包，输出到 build/ 目录
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
xcodegen generate
xcodebuild archive \
  -project SynoMusic.xcodeproj \
  -scheme SynoMusic \
  -configuration Release \
  -archivePath build/SynoMusic.xcarchive \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  PROVISIONING_PROFILE_SPECIFIER="" \
  ENTITLEMENTS_REQUIRED=NO

APP=build/SynoMusic.xcarchive/Products/Applications/SynoMusic.app
[ -d "$APP" ] || { echo "Archive 失败"; exit 1; }

rm -rf build/ipa-stage build/SynoMusic-unsigned.ipa
mkdir -p build/ipa-stage/Payload
cp -R "$APP" build/ipa-stage/Payload/SynoMusic.app
(cd build/ipa-stage && zip -qr ../SynoMusic-unsigned.ipa Payload)

ls -lh build/SynoMusic-unsigned.ipa
echo "✅ 未签名 IPA: build/SynoMusic-unsigned.ipa"
echo "  用 AltStore / Sideloadly / Feather 自签后侧载到设备。"
