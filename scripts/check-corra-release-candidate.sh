#!/usr/bin/env bash
set -u

LATEST_RELEASE="$(ls -td release/corra-booth-* 2>/dev/null | head -1)"
FAILURES=0

echo "Corra Release Candidate Check"
echo "============================="

if [ -z "$LATEST_RELEASE" ]; then
  echo "❌ release folder"
  exit 1
fi

has_file() {
  local label="$1"
  shift

  for file in "$@"; do
    if [ -f "$file" ]; then
      echo "✅ $label"
      return 0
    fi
  done

  echo "❌ $label"
  FAILURES=$((FAILURES + 1))
  return 0
}

has_dir() {
  local label="$1"
  shift

  for dir in "$@"; do
    if [ -d "$dir" ]; then
      echo "✅ $label"
      return 0
    fi
  done

  echo "❌ $label"
  FAILURES=$((FAILURES + 1))
  return 0
}

has_file "booth package/manifest" \
  "$LATEST_RELEASE/bundle/release-manifest.json" \
  "$LATEST_RELEASE/release-manifest.json" \
  "$LATEST_RELEASE/apps/booth-ui/package.json" \
  "$LATEST_RELEASE/booth-ui/package.json"

has_file "booth dist" \
  "$LATEST_RELEASE/bundle/booth-ui-dist/index.html" \
  "$LATEST_RELEASE/booth-ui-dist/index.html" \
  "$LATEST_RELEASE/apps/booth-ui/dist/index.html" \
  "$LATEST_RELEASE/booth-ui/dist/index.html" \
  "$LATEST_RELEASE/dist/index.html"

has_dir "desktop electron" \
  "$LATEST_RELEASE/bundle/apps/desktop-electron" \
  "$LATEST_RELEASE/apps/desktop-electron" \
  "$LATEST_RELEASE/desktop-electron" \
  "$LATEST_RELEASE/electron"

has_file "electron main" \
  "$LATEST_RELEASE/bundle/apps/desktop-electron/main.cjs" \
  "$LATEST_RELEASE/bundle/apps/desktop-electron/index.cjs" \
  "$LATEST_RELEASE/apps/desktop-electron/main.cjs" \
  "$LATEST_RELEASE/apps/desktop-electron/index.cjs" \
  "$LATEST_RELEASE/desktop-electron/main.cjs" \
  "$LATEST_RELEASE/desktop-electron/index.cjs" \
  "$LATEST_RELEASE/electron/main.cjs" \
  "$LATEST_RELEASE/electron/index.cjs"

has_file "electron preload" \
  "$LATEST_RELEASE/bundle/apps/desktop-electron/preload.cjs" \
  "$LATEST_RELEASE/apps/desktop-electron/preload.cjs" \
  "$LATEST_RELEASE/desktop-electron/preload.cjs" \
  "$LATEST_RELEASE/electron/preload.cjs"

has_file "disk bridge" \
  "$LATEST_RELEASE/bundle/apps/desktop-electron/corra-disk-persistence.cjs" \
  "$LATEST_RELEASE/apps/desktop-electron/corra-disk-persistence.cjs" \
  "$LATEST_RELEASE/desktop-electron/corra-disk-persistence.cjs" \
  "$LATEST_RELEASE/electron/corra-disk-persistence.cjs"

has_file "hardware bridge" \
  "$LATEST_RELEASE/bundle/apps/desktop-electron/corra-hardware-diagnostics.cjs" \
  "$LATEST_RELEASE/apps/desktop-electron/corra-hardware-diagnostics.cjs" \
  "$LATEST_RELEASE/desktop-electron/corra-hardware-diagnostics.cjs" \
  "$LATEST_RELEASE/electron/corra-hardware-diagnostics.cjs"

has_file "9G docs" \
  "$LATEST_RELEASE/bundle/docs/phase-9g-packaging-release-checklist.md" \
  "$LATEST_RELEASE/docs/phase-9g-packaging-release-checklist.md" \
  "docs/phase-9g-packaging-release-checklist.md"

echo ""
echo "Latest release:"
echo "$LATEST_RELEASE"

echo ""
echo "Important files:"
find "$LATEST_RELEASE" -maxdepth 5 -type f | sort | grep -E "release-manifest.json|index.html|main.cjs|index.cjs|preload.cjs|corra-" || true

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "✅ Release candidate structure looks good."
else
  echo "❌ Release candidate has $FAILURES issue(s)."
  exit 1
fi
