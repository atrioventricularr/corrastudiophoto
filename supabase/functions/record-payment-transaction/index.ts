import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type PaymentTransactionPayload = {
  id?: string;
  transactionId?: string;
  provider?: string;
  status?: string;
  amountIdr?: number;
  currency?: string;
  merchantName?: string;
  voucherCode?: string | null;
  confirmationCode?: string | null;
  failureReason?: string | null;
  cancelReason?: string | null;
  deviceFingerprint?: string | null;
  licenseCode?: string | null;
  source?: string;
  metadata?: Record<string, unknown>;
  createdAt?: string;
  updatedAt?: string;
  confirmedAt?: string | null;
  cancelledAt?: string | null;
};

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

function normalizePayload(payload: PaymentTransactionPayload) {
  const transactionId = payload.transactionId || payload.id;

  if (!transactionId) {
    throw new Error('Missing transaction id.');
  }

  if (!payload.provider) {
    throw new Error('Missing payment provider.');
  }

  if (!payload.status) {
    throw new Error('Missing payment status.');
  }

  return {
    transaction_id: transactionId,
    provider: payload.provider,
    status: payload.status,

    amount_idr: Number(payload.amountIdr || 0),
    currency: payload.currency || 'IDR',
    merchant_name: payload.merchantName || null,

    voucher_code: payload.voucherCode || null,
    confirmation_code: payload.confirmationCode || null,
    failure_reason: payload.failureReason || null,
    cancel_reason: payload.cancelReason || null,

    device_fingerprint: payload.deviceFingerprint || null,
    license_code: payload.licenseCode || null,

    source: payload.source || 'booth-ui',
    metadata: payload.metadata || {},

    client_created_at: payload.createdAt || null,
    client_updated_at: payload.updatedAt || null,
    confirmed_at: payload.confirmedAt || null,
    cancelled_at: payload.cancelledAt || null,

    synced_at: new Date().toISOString(),
  };
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders,
    });
  }

  if (request.method !== 'POST') {
    return jsonResponse(
      {
        ok: false,
        error: 'Method not allowed.',
      },
      405,
    );
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse(
        {
          ok: false,
          error:
            'Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in function secrets.',
        },
        500,
      );
    }

    const payload = (await request.json()) as PaymentTransactionPayload;
    const row = normalizePayload(payload);

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        persistSession: false,
      },
    });

    const { data, error } = await supabase
      .from('booth_payment_transactions')
      .upsert(row, {
        onConflict: 'transaction_id',
      })
      .select('*')
      .single();

    if (error) {
      return jsonResponse(
        {
          ok: false,
          error: error.message,
          details: error,
        },
        500,
      );
    }

    return jsonResponse({
      ok: true,
      transaction: data,
    });
  } catch (error) {
    return jsonResponse(
      {
        ok: false,
        error: error instanceof Error ? error.message : 'Unknown error.',
      },
      400,
    );
  }
});
