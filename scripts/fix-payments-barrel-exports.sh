#!/usr/bin/env bash
set -euo pipefail

PAYMENTS_DIR="apps/booth-ui/src/payments"
INDEX_FILE="$PAYMENTS_DIR/index.ts"

mkdir -p "$PAYMENTS_DIR"

cp "$INDEX_FILE" "$INDEX_FILE.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true

cat > "$INDEX_FILE" <<'TS'
// Payment barrel exports.
// Keep legacy payment exports + Phase 9D real payment exports here.

export * from './payment-settings-types';
export * from './PaymentSettingsProvider';
export * from './payment-transaction-types';
export * from './PaymentTransactionProvider';

export * from './doku-qris-api';
export * from './doku-status-api';
export * from './payment-status-api';

export * from './payment-sync-types';
export * from './supabase-payment-sync';

export * from './real-payment-types';
export * from './real-payment-storage';
export * from './real-payment-api';
export * from './mayar-checkout-api';
export * from './mayar-status-api';
export * from './RealPaymentRuntimePanel';
export * from './PaymentProviderDiagnosticsPanel';
TS

echo "Fixed payments/index.ts barrel exports."
