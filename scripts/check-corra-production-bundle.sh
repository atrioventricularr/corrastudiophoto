#!/usr/bin/env bash
set -u

LATEST="$(ls -td release/corra-booth-production-* 2>/dev/null | head -1)"
FAILURES=0

echo "Corra Production Bundle Check"
echo "============================="

if [ -z "$LATEST" ]; then
  echo "❌ production bundle"
  exit 1
fi

check_file() {
  if [ -f "$1" ]; then echo "✅ $2"; else echo "❌ $2"; FAILURES=$((FAILURES + 1)); fi
}

check_dir() {
  if [ -d "$1" ]; then echo "✅ $2"; else echo "❌ $2"; FAILURES=$((FAILURES + 1)); fi
}

check_file "$LATEST/bundle/release-manifest.json" "manifest"
check_file "$LATEST/bundle/booth-ui-dist/index.html" "booth dist index"
check_dir "$LATEST/bundle/apps/desktop-electron" "electron bundle"
check_file "$LATEST/bundle/apps/desktop-electron/main.cjs" "electron main"
check_file "$LATEST/bundle/apps/desktop-electron/preload.cjs" "electron preload"
check_file "$LATEST/bundle/apps/desktop-electron/corra-disk-persistence.cjs" "disk bridge"
check_file "$LATEST/bundle/apps/desktop-electron/corra-hardware-diagnostics.cjs" "hardware bridge"

echo ""
echo "Latest production bundle:"
echo "$LATEST"

if [ "$FAILURES" -gt 0 ]; then
  echo "❌ Production bundle has $FAILURES issue(s)."
  exit 1
fi

echo "✅ Production bundle structure looks good."
