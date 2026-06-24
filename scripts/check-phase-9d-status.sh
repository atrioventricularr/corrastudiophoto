#!/usr/bin/env bash
set -euo pipefail

f(){ [ -f "$2" ] && echo "✅ $1" || echo "❌ $1"; }

echo "Phase 9D Status"
echo "==============="

f "9D0 migration" supabase/migrations/023_booth_payment_intents.sql
f "9D1 create Mayar" supabase/functions/create-mayar-checkout/index.ts
f "9D2 check Mayar" supabase/functions/check-mayar-transaction-status/index.ts
f "9D3 Mayar webhook" supabase/functions/mayar-payment-webhook/index.ts
f "9D4 payment types" apps/booth-ui/src/payments/real-payment-types.ts
f "9D4 payment storage" apps/booth-ui/src/payments/real-payment-storage.ts
f "9D4 Mayar API" apps/booth-ui/src/payments/mayar-payment-api.ts
f "9D4 real payment API" apps/booth-ui/src/payments/real-payment-api.ts
f "9D5 runtime panel" apps/booth-ui/src/payments/RealPaymentRuntimePanel.tsx
f "9D6 diagnostics panel" apps/booth-ui/src/payments/PaymentProviderDiagnosticsPanel.tsx
f "9D8 docs" docs/phase-9d-real-payment-integration.md

pnpm --filter @corra/booth-ui exec tsc --noEmit --pretty false
