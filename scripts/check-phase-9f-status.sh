#!/usr/bin/env bash
set -euo pipefail

f(){ [ -f "$2" ] && echo "✅ $1" || echo "❌ $1"; }

echo "Phase 9F Status"
echo "==============="

f "9F1 hardware IPC" apps/desktop-electron/corra-hardware-diagnostics.cjs
f "9F2 hardware preload" apps/desktop-electron/corra-hardware-preload.cjs
f "9F3 types" apps/booth-ui/src/booth/booth-hardware-types.ts
f "9F3 api" apps/booth-ui/src/booth/booth-hardware-api.ts
f "9F3 storage" apps/booth-ui/src/booth/booth-hardware-test-storage.ts
f "9F4 diagnostics panel" apps/booth-ui/src/booth/BoothHardwareDiagnosticsPanel.tsx
f "9F5 printer panel" apps/booth-ui/src/booth/BoothPrinterHardwareTestPanel.tsx
f "9F6 camera panel" apps/booth-ui/src/booth/BoothCameraHardwareTestPanel.tsx
f "9F7 kiosk panel" apps/booth-ui/src/booth/BoothKioskHardwareTestPanel.tsx
f "9F8 readiness panel" apps/booth-ui/src/booth/BoothProductionReadinessPanel.tsx
f "9F11 patch script" scripts/patch-9f-electron-hardware-bridge.sh
f "9F12 checklist" docs/phase-9f-printer-kiosk-hardware-checklist.md

echo ""
echo "Electron bridge refs:"
grep -R \
  --exclude-dir=node_modules \
  --exclude-dir=dist \
  --exclude-dir=.vite \
  "corra-hardware-diagnostics\|corra-hardware-preload" \
  -n apps/desktop-electron || true

echo ""
pnpm --filter @corra/booth-ui exec tsc --noEmit --pretty false
