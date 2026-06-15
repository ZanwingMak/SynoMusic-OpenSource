#!/usr/bin/env bash
# Debug build for iOS Simulator (iPhone 17 Pro by default)
set -euo pipefail
cd "$(dirname "$0")/.."
DEVICE="${SIMULATOR:-iPhone 17 Pro}"
command -v xcodegen >/dev/null || { echo "xcodegen 未安装：brew install xcodegen"; exit 1; }
xcodegen generate
xcodebuild -project SynoMusic.xcodeproj -scheme SynoMusic \
  -destination "platform=iOS Simulator,name=$DEVICE,OS=latest" \
  -configuration Debug build
