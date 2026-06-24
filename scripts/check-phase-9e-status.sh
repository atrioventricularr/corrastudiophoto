#!/usr/bin/env bash
set -euo pipefail

f(){ [ -f "$2" ] && echo "✅ $1" || echo "❌ $1"; }

echo "Phase 9E Status"
echo "==============="

f "9E1 Electron IPC" apps/desktop-electron/corra-disk-persistence.cjs
f "9E2 Preload bridge" apps/desktop-electron/corra-disk-preload.cjs
f "9E3 Disk types" apps/booth-ui/src/booth/booth-disk-persistence-types.ts
f "9E3 Disk API" apps/booth-ui/src/booth/booth-disk-persistence-api.ts
f "9E4 Disk storage" apps/booth-ui/src/booth/booth-disk-persistence-storage.ts
f "9E4 Manifest" apps/booth-ui/src/booth/booth-disk-manifest.ts
f "9E5 Persistence panel" apps/booth-ui/src/booth/BoothDiskPersistencePanel.tsx
f "9E6 Browser panel" apps/booth-ui/src/booth/BoothDiskBrowserPanel.tsx
f "9E7 Retention panel" apps/booth-ui/src/booth/BoothDiskRetentionPanel.tsx
f "9E8 Delivery panel" apps/booth-ui/src/booth/BoothDeliveryDiskPanel.tsx
f "9E8 Checklist" docs/phase-9e-electron-disk-persistence-checklist.md

echo ""
pnpm --filter @corra/booth-ui exec tsc --noEmit --pretty false
