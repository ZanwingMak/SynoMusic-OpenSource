#!/usr/bin/env bash
# 一键模拟器打开：build + 启动模拟器 + 卸载旧 + 装新 + 启动
# 用法: ./scripts/sim.sh                # 普通启动
#       ./scripts/sim.sh -demo          # demo 假数据
#       ./scripts/sim.sh -demo -fullplayer
set -euo pipefail
cd "$(dirname "$0")/.."
DEVICE="${SIMULATOR:-iPhone 17 Pro}"
BUNDLE_ID="app.synomusic.SynoMusic"

bash scripts/build.sh

APP=$(find ~/Library/Developer/Xcode/DerivedData -name "SynoMusic.app" -path "*Debug-iphonesimulator*" 2>/dev/null | head -1)
[ -d "$APP" ] || { echo "没找到 SynoMusic.app，先跑 build.sh"; exit 1; }

xcrun simctl boot "$DEVICE" 2>/dev/null || true
open -a Simulator
sleep 2
xcrun simctl terminate booted "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl uninstall booted "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install booted "$APP"
xcrun simctl launch booted "$BUNDLE_ID" "$@"
echo "✅ 已启动 $BUNDLE_ID"
