#!/usr/bin/env bash
set -u

FAILURES=0
WARNINGS=0

ok(){ echo "✅ $1"; }
warn(){ echo "⚠️ $1"; WARNINGS=$((WARNINGS + 1)); }
fail(){ echo "❌ $1"; FAILURES=$((FAILURES + 1)); }

has_file(){ [ -f "$1" ] && ok "$2" || fail "$2"; }
has_dir(){ [ -d "$1" ] && ok "$2" || fail "$2"; }

echo "Corra Windows Installer Readiness"
echo "================================="

has_file "apps/desktop-electron/package.json" "desktop-electron package"
has_file "apps/desktop-electron/main.cjs" "electron main"
has_file "apps/desktop-electron/preload.cjs" "electron preload"
has_file "apps/desktop-electron/electron-builder.yml" "electron-builder config"
has_file "apps/desktop-electron/corra-disk-persistence.cjs" "disk IPC"
has_file "apps/desktop-electron/corra-hardware-diagnostics.cjs" "hardware IPC"

if [ -d "apps/booth-ui/dist" ]; then
  ok "booth UI dist exists"
else
  warn "booth UI dist missing; run pnpm --filter @corra/booth-ui build first"
fi

if command -v pnpm >/dev/null 2>&1; then ok "pnpm available"; else fail "pnpm available"; fi
if command -v node >/dev/null 2>&1; then ok "node available"; else fail "node available"; fi

if [ -n "${WINDOWS_CERT_THUMBPRINT:-}" ] || [ -n "${WINDOWS_PFX_PATH:-}" ]; then
  ok "code signing env appears configured"
else
  warn "code signing env not configured; unsigned installer only"
fi

echo ""
echo "Warnings: $WARNINGS"
echo "Failures: $FAILURES"

if [ "$FAILURES" -gt 0 ]; then
  exit 1
fi
