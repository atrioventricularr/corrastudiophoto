#!/usr/bin/env bash
set -euo pipefail

PAYMENTS_DIR="apps/booth-ui/src/payments"
INDEX_FILE="$PAYMENTS_DIR/index.ts"
COMPAT_FILE="$PAYMENTS_DIR/payment-compat-types.ts"

mkdir -p "$PAYMENTS_DIR"

cp "$INDEX_FILE" "$INDEX_FILE.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true

cat > "$COMPAT_FILE" <<'TS'
export type CorraPaymentProviderId =
  | 'STATIC_QRIS'
  | 'DOKU_QRIS'
  | 'MANUAL_CASH'
  | 'MAYAR_CHECKOUT';

export type CorraPaymentEnvironment = 'sandbox' | 'production';

export type CorraPaymentTransactionStatus =
  | 'pending'
  | 'waiting'
  | 'paid'
  | 'confirmed'
  | 'failed'
  | 'expired'
  | 'cancelled';

export type CorraPaymentTransaction = {
  id: string;
  sessionId?: string;
  providerId?: CorraPaymentProviderId;
  provider?: CorraPaymentProviderId;
  status: CorraPaymentTransactionStatus | string;
  amount?: number;
  currency?: string;
  customerName?: string;
  customerEmail?: string;
  externalId?: string;
  checkoutUrl?: string;
  qrString?: string;
  qrImageUrl?: string;
  syncStatus?: string;
  syncError?: string;
  createdAt?: string;
  updatedAt?: string;
  paidAt?: string;
};
TS

cat > "$INDEX_FILE" <<'TS'
// Safe payment barrel exports.
// This file intentionally exports only modules that exist in this project.

export * from './payment-compat-types';
TS

add_export() {
  local base="$1"

  if [ -f "$PAYMENTS_DIR/$base.ts" ] || [ -f "$PAYMENTS_DIR/$base.tsx" ]; then
    echo "export * from './$base';" >> "$INDEX_FILE"
  fi
}

add_export "PaymentSettingsProvider"
add_export "PaymentTransactionProvider"
add_export "doku-qris-api"
add_export "doku-status-api"
add_export "payment-status-api"
add_export "supabase-payment-sync"

add_export "real-payment-types"
add_export "real-payment-storage"
add_export "real-payment-api"
add_export "create-mayar-checkout-api"
add_export "check-mayar-transaction-status-api"
add_export "mayar-checkout-api"
add_export "mayar-status-api"
add_export "RealPaymentRuntimePanel"
add_export "PaymentProviderDiagnosticsPanel"

echo "Rewritten $INDEX_FILE safely."
echo ""
echo "Current payments files:"
ls -1 "$PAYMENTS_DIR"
