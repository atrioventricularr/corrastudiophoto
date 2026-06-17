#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8C2C1 - UI Sync Helper"
echo "========================================"

[ -f "apps/booth-ui/src/payments/transaction-types.ts" ] || {
  echo "ERROR: transaction-types.ts not found. Run 8C1 first."
  exit 1
}

mkdir -p apps/booth-ui/src/payments

cat > apps/booth-ui/src/payments/supabase-payment-sync.ts <<'TS'
import type { CorraPaymentTransaction } from './transaction-types';

const DEFAULT_FUNCTION_URL =
  'https://uitnzrstkjvwiojbnpwg.supabase.co/functions/v1/record-payment-transaction';

function getRecordPaymentTransactionUrl(): string {
  return (
    import.meta.env.VITE_RECORD_PAYMENT_TRANSACTION_URL ||
    DEFAULT_FUNCTION_URL
  );
}

function getSupabaseAnonKey(): string {
  return (
    import.meta.env.VITE_SUPABASE_ANON_KEY ||
    import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ||
    ''
  );
}

export type PaymentTransactionSyncResult = {
  ok: boolean;
  skipped?: boolean;
  error?: string;
  status?: number;
  syncedAt?: string;
  response?: unknown;
};

export function isPaymentTransactionSyncConfigured(): boolean {
  return Boolean(getRecordPaymentTransactionUrl() && getSupabaseAnonKey());
}

export async function syncPaymentTransactionToSupabase(
  transaction: CorraPaymentTransaction,
): Promise<PaymentTransactionSyncResult> {
  const url = getRecordPaymentTransactionUrl();
  const anonKey = getSupabaseAnonKey();

  if (!url || !anonKey) {
    return {
      ok: false,
      skipped: true,
      error:
        'Missing VITE_SUPABASE_ANON_KEY or VITE_SUPABASE_PUBLISHABLE_KEY.',
    };
  }

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${anonKey}`,
        apikey: anonKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        id: transaction.id,
        transactionId: transaction.id,
        provider: transaction.provider,
        status: transaction.status,
        amountIdr: transaction.amountIdr,
        currency: transaction.currency,
        merchantName: transaction.merchantName,
        voucherCode: transaction.voucherCode,
        confirmationCode: transaction.confirmationCode,
        failureReason: transaction.failureReason,
        cancelReason: transaction.cancelReason,
        source: 'booth-ui',
        metadata: transaction.metadata || {},
        createdAt: transaction.createdAt,
        updatedAt: transaction.updatedAt,
        confirmedAt: transaction.confirmedAt,
        cancelledAt: transaction.cancelledAt,
      }),
    });

    const responseBody = await response.json().catch(() => null);

    if (!response.ok) {
      return {
        ok: false,
        status: response.status,
        error:
          responseBody?.error ||
          responseBody?.message ||
          `Sync failed with status ${response.status}`,
        response: responseBody,
      };
    }

    return {
      ok: true,
      status: response.status,
      syncedAt: new Date().toISOString(),
      response: responseBody,
    };
  } catch (error) {
    return {
      ok: false,
      error:
        error instanceof Error
          ? error.message
          : 'Unknown payment transaction sync error.',
    };
  }
}
TS

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/payments/transaction-types.ts")
text = path.read_text()

if "syncStatus" not in text:
    text = text.replace(
        "  metadata?: Record<string, unknown>;",
        """  metadata?: Record<string, unknown>;
  syncStatus?: 'idle' | 'syncing' | 'synced' | 'failed' | 'skipped';
  syncedAt?: string | null;
  syncError?: string | null;"""
    )

if "syncPendingTransactions" not in text:
    text = text.replace(
        "  clearPaymentTransactions: () => void;",
        """  clearPaymentTransactions: () => void;
  syncPendingTransactions: () => Promise<void>;"""
    )

path.write_text(text)
print("PATCH file: apps/booth-ui/src/payments/transaction-types.ts")
PY

grep -q "supabase-payment-sync" apps/booth-ui/src/payments/index.ts || cat >> apps/booth-ui/src/payments/index.ts <<'TS'
export * from './supabase-payment-sync';
TS

if [ ! -f "apps/booth-ui/.env.local" ]; then
  cat > apps/booth-ui/.env.local <<'ENV'
VITE_RECORD_PAYMENT_TRANSACTION_URL=https://uitnzrstkjvwiojbnpwg.supabase.co/functions/v1/record-payment-transaction
VITE_SUPABASE_ANON_KEY=
ENV
else
  grep -q "VITE_RECORD_PAYMENT_TRANSACTION_URL" apps/booth-ui/.env.local || cat >> apps/booth-ui/.env.local <<'ENV'

VITE_RECORD_PAYMENT_TRANSACTION_URL=https://uitnzrstkjvwiojbnpwg.supabase.co/functions/v1/record-payment-transaction
VITE_SUPABASE_ANON_KEY=
ENV
fi

echo ""
echo "Created:"
echo "- apps/booth-ui/src/payments/supabase-payment-sync.ts"
echo ""
echo "Patched:"
echo "- apps/booth-ui/src/payments/transaction-types.ts"
echo "- apps/booth-ui/src/payments/index.ts"
echo "- apps/booth-ui/.env.local"
echo ""
echo "Phase 8C2C1 completed."
