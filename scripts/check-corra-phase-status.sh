#!/usr/bin/env bash
set -euo pipefail

f(){ [ -f "$2" ] && echo "✅ $1" || echo "❌ $1"; }

echo "Corra Booth Phase 9B Status"
echo "==========================="

f "9B1 FlowProvider" apps/booth-ui/src/booth/BoothFlowProvider.tsx
f "9B2 BoothModePage" apps/booth-ui/src/booth/BoothModePage.tsx
f "9B3 Welcome" apps/booth-ui/src/booth/BoothWelcomeStep.tsx
f "9B4 Payment" apps/booth-ui/src/booth/BoothPaymentStep.tsx
f "9B6 Camera" apps/booth-ui/src/booth/BoothCameraStep.tsx
f "9B7 Review" apps/booth-ui/src/booth/BoothReviewStep.tsx
f "9B8 Delivery" apps/booth-ui/src/booth/BoothDeliveryStep.tsx
f "9B9 Complete" apps/booth-ui/src/booth/BoothCompleteStep.tsx
f "9B10 Mode utils" apps/booth-ui/src/booth/booth-mode-utils.ts
f "9B11 Guard" apps/booth-ui/src/booth/BoothStepGuard.tsx
f "9B11 Boundary" apps/booth-ui/src/booth/BoothStepErrorBoundary.tsx
f "9B12 Lifecycle" apps/booth-ui/src/booth/BoothLifecycleLoggerProvider.tsx
f "9B13 Debug panel" apps/booth-ui/src/booth/BoothLifecycleDebugPanel.tsx
f "9B14 Local DB" apps/booth-ui/src/booth/booth-local-assets-db.ts
f "9B16 Asset panel" apps/booth-ui/src/booth/BoothLocalAssetsPanel.tsx
f "9B17 Cloud panel" apps/booth-ui/src/booth/BoothCloudUploadPanel.tsx
f "9B18 Upload function" supabase/functions/upload-booth-asset/index.ts
f "9B19 Kiosk safety" apps/booth-ui/src/booth/useBoothKioskSafety.ts
f "9B19 Kiosk unlock" apps/booth-ui/src/booth/BoothKioskAdminUnlock.tsx
f "9B20 Status doc" docs/phase-9b-status.md

echo ""
if pnpm --filter @corra/booth-ui exec tsc --noEmit --pretty false; then
  echo "✅ TypeScript clean"
else
  echo "❌ TypeScript error"
fi
