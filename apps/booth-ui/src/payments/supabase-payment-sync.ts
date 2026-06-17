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
