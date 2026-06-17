import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-signature, x-timestamp, x-partner-id, x-external-id, channel-id',
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

function getString(value: unknown): string {
  return typeof value === 'string' ? value : '';
}

function findStringByKeys(
  value: unknown,
  keys: string[],
): string {
  if (!value || typeof value !== 'object') {
    return '';
  }

  const objectValue = value as Record<string, unknown>;

  for (const key of keys) {
    const direct = getString(objectValue[key]);

    if (direct) {
      return direct;
    }
  }

  for (const item of Object.values(objectValue)) {
    if (item && typeof item === 'object') {
      const found = findStringByKeys(item, keys);

      if (found) {
        return found;
      }
    }
  }

  return '';
}

function inferStatus(payload: Record<string, unknown>) {
  const responseCode = findStringByKeys(payload, [
    'responseCode',
    'latestTransactionStatus',
    'transactionStatus',
    'status',
  ]).toLowerCase();

  const responseMessage = findStringByKeys(payload, [
    'responseMessage',
    'message',
    'transactionStatusDesc',
    'statusDesc',
  ]).toLowerCase();

  const successIndicators = [
    '200',
    '00',
    'success',
    'successful',
    'settlement',
    'settled',
    'paid',
    'capture',
    'completed',
  ];

  const failedIndicators = [
    'failed',
    'failure',
    'expired',
    'cancel',
    'cancelled',
    'deny',
    'denied',
    'void',
  ];

  if (
    successIndicators.some((indicator) =>
      responseCode.includes(indicator) || responseMessage.includes(indicator),
    )
  ) {
    return 'confirmed';
  }

  if (
    failedIndicators.some((indicator) =>
      responseCode.includes(indicator) || responseMessage.includes(indicator),
    )
  ) {
    return 'failed';
  }

  return 'pending';
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

    const payload = (await request.json()) as Record<string, unknown>;

    const transactionId =
      findStringByKeys(payload, [
        'partnerReferenceNo',
        'originalPartnerReferenceNo',
        'referenceNo',
        'invoiceNumber',
        'orderId',
        'transactionId',
      ]) || crypto.randomUUID();

    const dokuReferenceNo = findStringByKeys(payload, [
      'referenceNo',
      'originalReferenceNo',
      'issuerReferenceNo',
      'acquirerReferenceNo',
    ]);

    const status = inferStatus(payload);
    const now = new Date().toISOString();

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        persistSession: false,
      },
    });

    const row = {
      transaction_id: transactionId,
      provider: 'DOKU_QRIS',
      status,
      source: 'doku-payment-notification',
      confirmation_code:
        status === 'confirmed'
          ? dokuReferenceNo || `DOKU_CONFIRMED_${transactionId}`
          : null,
      failure_reason:
        status === 'failed'
          ? findStringByKeys(payload, [
              'responseMessage',
              'message',
              'transactionStatusDesc',
              'statusDesc',
            ]) || 'DOKU payment failed'
          : null,
      metadata: {
        dokuReferenceNo,
        notificationReceivedAt: now,
        rawNotification: payload,
      },
      client_updated_at: now,
      confirmed_at: status === 'confirmed' ? now : null,
      synced_at: now,
    };

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
      transactionId,
      status,
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
