#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8D2B1 - DOKU Status UI Helper"
echo "========================================"

mkdir -p apps/booth-ui/src/payments

cat > apps/booth-ui/src/payments/doku-status-api.ts <<'TS'
export type CheckDokuQrisStatusInput = {
  transactionId: string;
  originalReferenceNo?: string;
  originalExternalId?: string;
  environment?: 'sandbox' | 'production';
};

export type CheckDokuQrisStatusResult = {
  ok: boolean;
  transactionId?: string;
  status?: 'pending' | 'confirmed' | 'failed' | string;
  environment?: 'sandbox' | 'production';
  doku?: Record<string, unknown>;
  transactionRecord?: Record<string, unknown> | null;
  transactionRecordError?: string | null;
  error?: string | null;
};

const DEFAULT_CHECK_DOKU_QRIS_STATUS_URL =
  'https://uitnzrstkjvwiojbnpwg.supabase.co/functions/v1/check-doku-qris-status';

function getCheckDokuQrisStatusUrl(): string {
  return (
    import.meta.env.VITE_CHECK_DOKU_QRIS_STATUS_URL ||
    DEFAULT_CHECK_DOKU_QRIS_STATUS_URL
  );
}

function getSupabaseAnonKey(): string {
  return (
    import.meta.env.VITE_SUPABASE_ANON_KEY ||
    import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ||
    ''
  );
}

export function isCheckDokuQrisStatusConfigured(): boolean {
  return Boolean(getCheckDokuQrisStatusUrl() && getSupabaseAnonKey());
}

export async function checkDokuQrisStatus(
  input: CheckDokuQrisStatusInput,
): Promise<CheckDokuQrisStatusResult> {
  const url = getCheckDokuQrisStatusUrl();
  const anonKey = getSupabaseAnonKey();

  if (!url || !anonKey) {
    return {
      ok: false,
      transactionId: input.transactionId,
      status: 'not_configured',
      error:
        'Missing VITE_CHECK_DOKU_QRIS_STATUS_URL or VITE_SUPABASE_ANON_KEY.',
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
      body: JSON.stringify(input),
    });

    const body = (await response.json().catch(() => null)) as
      | CheckDokuQrisStatusResult
      | null;

    if (!response.ok) {
      return {
        ok: false,
        transactionId: input.transactionId,
        status: 'error',
        error:
          body?.error ||
          `Check DOKU QRIS status failed with status ${response.status}`,
        doku: body?.doku,
        transactionRecord: body?.transactionRecord,
        transactionRecordError: body?.transactionRecordError,
      };
    }

    return (
      body || {
        ok: false,
        transactionId: input.transactionId,
        status: 'empty_response',
        error: 'Empty check DOKU QRIS status response.',
      }
    );
  } catch (error) {
    return {
      ok: false,
      transactionId: input.transactionId,
      status: 'network_error',
      error:
        error instanceof Error
          ? error.message
          : 'Unknown check DOKU QRIS status error.',
    };
  }
}
TS

grep -q "doku-status-api" apps/booth-ui/src/payments/index.ts || cat >> apps/booth-ui/src/payments/index.ts <<'TS'
export * from './doku-status-api';
TS

if [ ! -f "apps/booth-ui/.env.local" ]; then
  cat > apps/booth-ui/.env.local <<'ENV'
VITE_CHECK_DOKU_QRIS_STATUS_URL=https://uitnzrstkjvwiojbnpwg.supabase.co/functions/v1/check-doku-qris-status
VITE_SUPABASE_ANON_KEY=
ENV
else
  grep -q "VITE_CHECK_DOKU_QRIS_STATUS_URL" apps/booth-ui/.env.local || cat >> apps/booth-ui/.env.local <<'ENV'

VITE_CHECK_DOKU_QRIS_STATUS_URL=https://uitnzrstkjvwiojbnpwg.supabase.co/functions/v1/check-doku-qris-status
ENV
fi

echo ""
echo "Created:"
echo "- apps/booth-ui/src/payments/doku-status-api.ts"
echo ""
echo "Patched:"
echo "- apps/booth-ui/src/payments/index.ts"
echo "- apps/booth-ui/.env.local"
echo ""
echo "Phase 8D2B1 completed."
