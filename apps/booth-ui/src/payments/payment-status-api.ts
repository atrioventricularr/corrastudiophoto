export type PaymentTransactionRemoteStatus =
  | 'pending'
  | 'confirmed'
  | 'voucher_used'
  | 'cancelled'
  | 'failed'
  | 'not_found'
  | string;

export type GetPaymentTransactionStatusInput = {
  transactionId: string;
};

export type GetPaymentTransactionStatusResult = {
  ok: boolean;
  found?: boolean;
  transactionId?: string;
  status?: PaymentTransactionRemoteStatus;
  transaction?: Record<string, unknown>;
  error?: string;
};

const DEFAULT_GET_PAYMENT_STATUS_URL =
  'https://uitnzrstkjvwiojbnpwg.supabase.co/functions/v1/get-payment-transaction-status';

function getPaymentStatusUrl(): string {
  return (
    import.meta.env.VITE_GET_PAYMENT_STATUS_URL ||
    DEFAULT_GET_PAYMENT_STATUS_URL
  );
}

function getSupabaseAnonKey(): string {
  return (
    import.meta.env.VITE_SUPABASE_ANON_KEY ||
    import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ||
    ''
  );
}

export function isPaymentStatusApiConfigured(): boolean {
  return Boolean(getPaymentStatusUrl() && getSupabaseAnonKey());
}

export async function getPaymentTransactionStatus(
  input: GetPaymentTransactionStatusInput,
): Promise<GetPaymentTransactionStatusResult> {
  const url = getPaymentStatusUrl();
  const anonKey = getSupabaseAnonKey();

  if (!url || !anonKey) {
    return {
      ok: false,
      found: false,
      transactionId: input.transactionId,
      status: 'not_configured',
      error:
        'Missing VITE_GET_PAYMENT_STATUS_URL or VITE_SUPABASE_ANON_KEY.',
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
        transactionId: input.transactionId,
      }),
    });

    const body = (await response.json().catch(() => null)) as
      | GetPaymentTransactionStatusResult
      | null;

    if (!response.ok) {
      return {
        ok: false,
        found: false,
        transactionId: input.transactionId,
        status: 'error',
        error:
          body?.error ||
          `Get payment status failed with status ${response.status}`,
        transaction: body?.transaction,
      };
    }

    return (
      body || {
        ok: false,
        found: false,
        transactionId: input.transactionId,
        status: 'empty_response',
        error: 'Empty payment status response.',
      }
    );
  } catch (error) {
    return {
      ok: false,
      found: false,
      transactionId: input.transactionId,
      status: 'network_error',
      error:
        error instanceof Error
          ? error.message
          : 'Unknown payment status error.',
    };
  }
}
