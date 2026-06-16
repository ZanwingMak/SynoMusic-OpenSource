#!/usr/bin/env bash
# 打包 IPA + 源码 zip 并发布到 GitHub Release
# 用法: ./scripts/release.sh v1.1.0 "SynoMusic 1.1.0"
set -euo pipefail
cd "$(dirname "$0")/.."

TAG="${1:-}"
TITLE="${2:-$TAG}"
[ -n "$TAG" ] || { echo "用法: $0 <tag> [<title>]"; exit 1; }

command -v gh >/dev/null || { echo "需要 gh CLI: brew install gh"; exit 1; }

bash scripts/archive_ipa.sh

IPA="build/SynoMusic-unsigned.ipa"
SRC="build/SynoMusic-${TAG#v}-source.zip"

git archive --format=zip -o "$SRC" --prefix="SynoMusic-${TAG#v}/" HEAD

# 若 tag 不存在则创建并推送
git rev-parse "$TAG" >/dev/null 2>&1 || {
  git tag "$TAG"
  git push origin "$TAG"
}

# 删除可能存在的旧 release（保留 tag）
gh release delete "$TAG" --yes 2>/dev/null || true

# release notes 优先取 `[<version>]` 段；缺则回落 `[Unreleased]`
NOTES_FILE=$(mktemp)
VER="${TAG#v}"
awk -v ver="$VER" '
  $0 ~ "^## \\[" ver "\\]" {p=1;next}
  p && /^## \[/{exit}
  p
' CHANGELOG.md > "$NOTES_FILE" || true
if [ ! -s "$NOTES_FILE" ]; then
  awk '/^## \[Unreleased\]/{p=1;next} p && /^## \[/{exit} p' CHANGELOG.md > "$NOTES_FILE" || true
fi
[ -s "$NOTES_FILE" ] || echo "See CHANGELOG.md" > "$NOTES_FILE"

mv build/SynoMusic-unsigned.ipa "build/SynoMusic-${TAG#v}-unsigned.ipa"

gh release create "$TAG" \
  --title "$TITLE" \
  --notes-file "$NOTES_FILE" \
  "build/SynoMusic-${TAG#v}-unsigned.ipa" "$SRC"

echo "✅ Release 已推送: $(gh release view "$TAG" --json url --jq .url)"
