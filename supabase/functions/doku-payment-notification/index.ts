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


function arrayBufferToHexLower(buffer: ArrayBuffer): string {
  return Array.from(new Uint8Array(buffer))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('')
    .toLowerCase();
}

function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = '';

  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }

  return btoa(binary);
}

async function sha256HexLower(value: string): Promise<string> {
  const buffer = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(value),
  );

  return arrayBufferToHexLower(buffer);
}

async function hmacSha512Base64(
  secret: string,
  stringToSign: string,
): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    {
      name: 'HMAC',
      hash: 'SHA-512',
    },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(stringToSign),
  );

  return arrayBufferToBase64(signature);
}

function timingSafeEqual(a: string, b: string): boolean {
  const encoder = new TextEncoder();
  const aBytes = encoder.encode(a);
  const bBytes = encoder.encode(b);

  if (aBytes.length !== bBytes.length) {
    return false;
  }

  let result = 0;

  for (let index = 0; index < aBytes.length; index += 1) {
    result |= aBytes[index] ^ bBytes[index];
  }

  return result === 0;
}

function getRequestTarget(request: Request): string {
  const url = new URL(request.url);

  return url.pathname;
}

async function verifyDokuSnapSignature(params: {
  request: Request;
  rawBody: string;
  clientSecret: string;
}) {
  const signature = params.request.headers.get('x-signature') || '';
  const timestamp = params.request.headers.get('x-timestamp') || '';
  const authorization =
    params.request.headers.get('authorization') ||
    params.request.headers.get('Authorization') ||
    '';

  if (!signature || !timestamp || !authorization) {
    return {
      valid: false,
      reason: 'Missing X-SIGNATURE, X-TIMESTAMP, or Authorization header.',
      expectedSignature: '',
      stringToSign: '',
    };
  }

  const accessToken = authorization.replace(/^Bearer\s+/i, '').trim();
  const requestTarget = getRequestTarget(params.request);
  const bodyHash = await sha256HexLower(params.rawBody);
  const stringToSign = [
    params.request.method.toUpperCase(),
    requestTarget,
    accessToken,
    bodyHash,
    timestamp,
  ].join(':');

  const expectedSignature = await hmacSha512Base64(
    params.clientSecret,
    stringToSign,
  );

  return {
    valid: timingSafeEqual(signature, expectedSignature),
    reason: timingSafeEqual(signature, expectedSignature)
      ? 'Signature valid.'
      : 'Signature mismatch.',
    expectedSignature,
    stringToSign,
  };
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

    const rawBody = await request.text();
    const payload = JSON.parse(rawBody) as Record<string, unknown>;

    const shouldVerifySignature =
      Deno.env.get('DOKU_VERIFY_WEBHOOK_SIGNATURE') === 'true';

    let signatureVerification:
      | {
          valid: boolean;
          reason: string;
          expectedSignature: string;
          stringToSign: string;
        }
      | null = null;

    if (shouldVerifySignature) {
      const clientSecret = Deno.env.get('DOKU_CLIENT_SECRET');

      if (!clientSecret) {
        return jsonResponse(
          {
            ok: false,
            error:
              'DOKU_VERIFY_WEBHOOK_SIGNATURE=true but DOKU_CLIENT_SECRET is missing.',
          },
          500,
        );
      }

      signatureVerification = await verifyDokuSnapSignature({
        request,
        rawBody,
        clientSecret,
      });

      if (!signatureVerification.valid) {
        return jsonResponse(
          {
            ok: false,
            error: 'Invalid DOKU webhook signature.',
            reason: signatureVerification.reason,
          },
          401,
        );
      }
    }

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
