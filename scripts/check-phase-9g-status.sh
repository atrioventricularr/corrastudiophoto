#!/usr/bin/env bash
set -euo pipefail

f(){ [ -f "$2" ] && echo "✅ $1" || echo "❌ $1"; }

echo "Phase 9G Status"
echo "==============="
f "9G1 release types" apps/booth-ui/src/booth/booth-release-types.ts
f "9G1 readiness storage" apps/booth-ui/src/booth/booth-release-readiness-storage.ts
f "9G2 diagnostics" apps/booth-ui/src/booth/booth-release-diagnostics.ts
f "9G3 diagnostics panel" apps/booth-ui/src/booth/BoothReleaseDiagnosticsPanel.tsx
f "9G3 readiness panel" apps/booth-ui/src/booth/BoothReleaseReadinessPanel.tsx
f "9G4 manifest panel" apps/booth-ui/src/booth/BoothReleaseManifestPanel.tsx
f "9G7 release env" scripts/corra-release-env.sh
f "9G7 build UI" scripts/build-booth-ui-release.sh
f "9G7 make RC" scripts/make-corra-release-candidate.sh
f "9G7 check RC" scripts/check-corra-release-candidate.sh
f "9G9 docs" docs/phase-9g-packaging-release-checklist.md
f "9G10 status" docs/phase-9g-status.md

echo ""
pnpm --filter @corra/booth-ui exec tsc --noEmit --pretty false
