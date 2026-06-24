#!/usr/bin/env bash
set -euo pipefail

f(){ [ -f "$2" ] && echo "✅ $1" || echo "❌ $1"; }

echo "Phase 11 Status"
echo "==============="

f "11A types" apps/booth-ui/src/booth/booth-installer-readiness-types.ts
f "11A storage" apps/booth-ui/src/booth/booth-installer-readiness-storage.ts
f "11B panel" apps/booth-ui/src/booth/BoothInstallerReadinessPanel.tsx
f "11C electron-builder config" apps/desktop-electron/electron-builder.yml
f "11D readiness script" scripts/check-windows-installer-readiness.sh
f "11D build installer script" scripts/build-windows-installer.sh
f "11D output checker" scripts/check-windows-installer-output.sh
f "11E signing script" scripts/sign-windows-artifacts.ps1
f "11F smoke checklist" scripts/run-windows-smoke-test-checklist.ps1
f "11G docs" docs/phase-11-windows-installer-signing-checklist.md
f "11G status" docs/phase-11-status.md

echo ""
pnpm --filter @corra/booth-ui exec tsc --noEmit --pretty false
