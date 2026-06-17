export type CreateDokuQrisInput = {
  transactionId: string;
  amountIdr: number;
  merchantId?: string;
  terminalId?: string;
  environment?: 'sandbox' | 'production';
  validityMinutes?: number;
};

export type CreateDokuQrisResult = {
  ok: boolean;
  transactionId?: string;
  environment?: 'sandbox' | 'production';
  request?: {
    partnerReferenceNo?: string;
    amountIdr?: number;
    merchantId?: string;
    terminalId?: string;
    validityPeriod?: string;
  };
  doku?: Record<string, unknown>;
  error?: string | null;
};

const DEFAULT_CREATE_DOKU_QRIS_URL =
  'https://uitnzrstkjvwiojbnpwg.supabase.co/functions/v1/create-doku-qris';

function getCreateDokuQrisUrl(): string {
  return (
    import.meta.env.VITE_CREATE_DOKU_QRIS_URL ||
    DEFAULT_CREATE_DOKU_QRIS_URL
  );
}

function getSupabaseAnonKey(): string {
  return (
    import.meta.env.VITE_SUPABASE_ANON_KEY ||
    import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ||
    ''
  );
}

export function isCreateDokuQrisConfigured(): boolean {
  return Boolean(getCreateDokuQrisUrl() && getSupabaseAnonKey());
}

export async function createDokuQris(
  input: CreateDokuQrisInput,
): Promise<CreateDokuQrisResult> {
  const url = getCreateDokuQrisUrl();
  const anonKey = getSupabaseAnonKey();

  if (!url || !anonKey) {
    return {
      ok: false,
      error:
        'Missing VITE_CREATE_DOKU_QRIS_URL or VITE_SUPABASE_ANON_KEY.',
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
      | CreateDokuQrisResult
      | null;

    if (!response.ok) {
      return {
        ok: false,
        error:
          body?.error ||
          `Create DOKU QRIS failed with status ${response.status}`,
        doku: body?.doku,
      };
    }

    return body || {
      ok: false,
      error: 'Empty create DOKU QRIS response.',
    };
  } catch (error) {
    return {
      ok: false,
      error:
        error instanceof Error
          ? error.message
          : 'Unknown create DOKU QRIS error.',
    };
  }
}
