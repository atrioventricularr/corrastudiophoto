#!/usr/bin/env bash
set -u

FAILURES=0
WARNINGS=0

ok(){ echo "✅ $1"; }
warn(){ echo "⚠️ $1"; WARNINGS=$((WARNINGS + 1)); }
fail(){ echo "❌ $1"; FAILURES=$((FAILURES + 1)); }

has_file(){ [ -f "$1" ] && ok "$2" || fail "$2"; }
has_dir(){ [ -d "$1" ] && ok "$2" || fail "$2"; }

echo "Corra Production Audit"
echo "======================"

has_file "apps/booth-ui/package.json" "booth-ui package"
has_file "apps/desktop-electron/package.json" "desktop-electron package"
has_file "apps/desktop-electron/main.cjs" "electron main"
has_file "apps/desktop-electron/preload.cjs" "electron preload"
has_file "apps/desktop-electron/corra-disk-persistence.cjs" "disk IPC"
has_file "apps/desktop-electron/corra-hardware-diagnostics.cjs" "hardware IPC"
has_dir "supabase/functions" "supabase functions"

SECRET_SCAN="$(grep -R \
  --exclude-dir=node_modules \
  --exclude-dir=dist \
  --exclude-dir=.vite \
  --exclude-dir=release \
  "SUPABASE_SERVICE_ROLE_KEY\|MAYAR_API_KEY" \
  -n apps/booth-ui apps/desktop-electron supabase/functions 2>/dev/null \
  | grep -v "Deno.env" \
  | grep -v "process.env" \
  | grep -v "secrets set" || true)"

if [ -n "$SECRET_SCAN" ]; then
  warn "possible frontend secret references found"
  echo "$SECRET_SCAN"
else
  ok "no obvious frontend service-role/mayar secret literals"
fi

if [ -f "apps/booth-ui/.env.local" ]; then
  grep -q "VITE_SUPABASE_ANON_KEY=" apps/booth-ui/.env.local && ok "VITE_SUPABASE_ANON_KEY present" || warn "VITE_SUPABASE_ANON_KEY missing"
  grep -q "VITE_UPLOAD_BOOTH_ASSET_URL=" apps/booth-ui/.env.local && ok "cloud upload URL present" || warn "cloud upload URL missing"
  grep -q "VITE_CREATE_MAYAR_CHECKOUT_URL=" apps/booth-ui/.env.local && ok "Mayar checkout URL present" || warn "Mayar checkout URL missing"
else
  warn "apps/booth-ui/.env.local missing"
fi

echo ""
echo "Warnings: $WARNINGS"
echo "Failures: $FAILURES"

if [ "$FAILURES" -gt 0 ]; then
  exit 1
fi
