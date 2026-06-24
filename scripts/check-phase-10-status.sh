#!/usr/bin/env bash
set -euo pipefail

f(){ [ -f "$2" ] && echo "✅ $1" || echo "❌ $1"; }

echo "Phase 10 Status"
echo "==============="

f "10A types" apps/booth-ui/src/booth/booth-production-security-types.ts
f "10A storage" apps/booth-ui/src/booth/booth-production-security-storage.ts
f "10B panel" apps/booth-ui/src/booth/BoothProductionSecurityPanel.tsx
f "10C audit" scripts/audit-corra-production.sh
f "10C build bundle" scripts/build-corra-production-bundle.sh
f "10C check bundle" scripts/check-corra-production-bundle.sh
f "10D production launcher" apps/desktop-electron/RUN-PRODUCTION-WINDOWS.cmd
f "10D dev launcher" apps/desktop-electron/RUN-DEV-WINDOWS.cmd
f "10G checklist" docs/phase-10-production-hardening-checklist.md
f "10G status" docs/phase-10-status.md

echo ""
pnpm --filter @corra/booth-ui exec tsc --noEmit --pretty false
