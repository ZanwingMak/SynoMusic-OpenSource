#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
DEVICE="${SIMULATOR:-iPhone 17 Pro}"
xcodebuild test -project SynoMusic.xcodeproj -scheme SynoMusic \
  -destination "platform=iOS Simulator,name=$DEVICE,OS=latest" \
  -only-testing:SynoMusicTests
