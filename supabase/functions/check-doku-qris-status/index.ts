import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type CheckDokuQrisStatusPayload = {
  transactionId?: string;
  originalReferenceNo?: string;
  originalExternalId?: string;
  environment?: 'sandbox' | 'production';
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

function getDokuBaseUrl(environment: 'sandbox' | 'production') {
  return environment === 'production'
    ? 'https://api.doku.com'
    : 'https://api-sandbox.doku.com';
}

function createTimestampJakarta(): string {
  const date = new Date();
  const jakartaMs = date.getTime() + 7 * 60 * 60 * 1000;
  const jakarta = new Date(jakartaMs);

  return jakarta.toISOString().replace('Z', '+07:00');
}

function createExternalId(): string {
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);

  return Array.from(bytes)
    .map((byte) => byte.toString().padStart(3, '0'))
    .join('')
    .slice(0, 36);
}

function stripPem(pem: string): string {
  return pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/-----BEGIN RSA PRIVATE KEY-----/g, '')
    .replace(/-----END RSA PRIVATE KEY-----/g, '')
    .replace(/\s+/g, '');
}

function base64ToArrayBuffer(base64: string): ArrayBuffer {
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);

  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }

  return bytes.buffer;
}

function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = '';

  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }

  return btoa(binary);
}

async function importPrivateKey(privateKeyPem: string): Promise<CryptoKey> {
  const keyData = base64ToArrayBuffer(stripPem(privateKeyPem));

  return crypto.subtle.importKey(
    'pkcs8',
    keyData,
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256',
    },
    false,
    ['sign'],
  );
}

async function createRsaSignature(
  privateKeyPem: string,
  stringToSign: string,
): Promise<string> {
  const privateKey = await importPrivateKey(privateKeyPem);
  const encoded = new TextEncoder().encode(stringToSign);

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    encoded,
  );

  return arrayBufferToBase64(signature);
}

async function sha256HexLower(value: string): Promise<string> {
  const buffer = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(value),
  );

  return Array.from(new Uint8Array(buffer))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('')
    .toLowerCase();
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

async function getB2BToken(params: {
  baseUrl: string;
  clientId: string;
  privateKey: string;
}) {
  const path = '/authorization/v1/access-token/b2b';
  const timestamp = createTimestampJakarta();
  const stringToSign = `${params.clientId}|${timestamp}`;
  const signature = await createRsaSignature(params.privateKey, stringToSign);

  const response = await fetch(`${params.baseUrl}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-TIMESTAMP': timestamp,
      'X-CLIENT-KEY': params.clientId,
      'X-SIGNATURE': signature,
    },
    body: JSON.stringify({
      grantType: 'client_credentials',
    }),
  });

  const body = await response.json().catch(() => null);

  if (!response.ok || !body?.accessToken) {
    throw new Error(
      `DOKU B2B token failed: ${body?.responseMessage || response.status}`,
    );
  }

  return body.accessToken as string;
}

async function createTransactionSignature(params: {
  method: string;
  path: string;
  accessToken: string;
  requestBody: unknown;
  timestamp: string;
  clientSecret: string;
}) {
  const bodyHash = await sha256HexLower(JSON.stringify(params.requestBody));
  const stringToSign = [
    params.method,
    params.path,
    params.accessToken,
    bodyHash,
    params.timestamp,
  ].join(':');

  return hmacSha512Base64(params.clientSecret, stringToSign);
}

function inferStatus(dokuBody: Record<string, unknown> | null) {
  const raw = JSON.stringify(dokuBody || {}).toLowerCase();

  if (
    raw.includes('success') ||
    raw.includes('paid') ||
    raw.includes('settlement') ||
    raw.includes('settled') ||
    raw.includes('completed') ||
    raw.includes('"00"') ||
    raw.includes('200')
  ) {
    return 'confirmed';
  }

  if (
    raw.includes('failed') ||
    raw.includes('expired') ||
    raw.includes('cancel') ||
    raw.includes('denied')
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
    return jsonResponse({ ok: false, error: 'Method not allowed.' }, 405);
  }

  try {
    const payload = (await request.json()) as CheckDokuQrisStatusPayload;

    const transactionId = payload.transactionId?.trim();

    if (!transactionId) {
      return jsonResponse(
        { ok: false, error: 'Missing transactionId.' },
        400,
      );
    }

    const environment = payload.environment || 'sandbox';
    const baseUrl = getDokuBaseUrl(environment);

    const clientId = Deno.env.get('DOKU_CLIENT_ID');
    const clientSecret = Deno.env.get('DOKU_CLIENT_SECRET');
    const privateKey = Deno.env.get('DOKU_PRIVATE_KEY');

    if (!clientId || !clientSecret || !privateKey) {
      return jsonResponse(
        {
          ok: false,
          error:
            'Missing DOKU env. Required: DOKU_CLIENT_ID, DOKU_CLIENT_SECRET, DOKU_PRIVATE_KEY.',
        },
        500,
      );
    }

    const accessToken = await getB2BToken({
      baseUrl,
      clientId,
      privateKey,
    });

    const path = '/snap/v1.1/qr/qr-mpm-status';
    const timestamp = createTimestampJakarta();
    const externalId = createExternalId();

    const checkBody = {
      originalPartnerReferenceNo: transactionId,
      originalReferenceNo: payload.originalReferenceNo || transactionId,
      originalExternalId: payload.originalExternalId || externalId,
      serviceCode: '43',
    };

    const signature = await createTransactionSignature({
      method: 'POST',
      path,
      accessToken,
      requestBody: checkBody,
      timestamp,
      clientSecret,
    });

    const dokuResponse = await fetch(`${baseUrl}${path}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-PARTNER-ID': clientId,
        'X-EXTERNAL-ID': externalId,
        'X-TIMESTAMP': timestamp,
        'X-SIGNATURE': signature,
        Authorization: `Bearer ${accessToken}`,
        'CHANNEL-ID': 'H2H',
      },
      body: JSON.stringify(checkBody),
    });

    const dokuBody = await dokuResponse.json().catch(() => null);
    const status = inferStatus(dokuBody);

    let transactionRecord = null;
    let transactionRecordError = null;

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (supabaseUrl && serviceRoleKey) {
      const supabase = createClient(supabaseUrl, serviceRoleKey, {
        auth: {
          persistSession: false,
        },
      });

      const { data, error } = await supabase
        .from('booth_payment_transactions')
        .upsert(
          {
            transaction_id: transactionId,
            provider: 'DOKU_QRIS',
            status,
            source: 'check-doku-qris-status',
            confirmation_code:
              status === 'confirmed'
                ? `DOKU_STATUS_CONFIRMED_${transactionId}`
                : null,
            failure_reason:
              status === 'failed' ? 'DOKU status inquiry returned failed.' : null,
            metadata: {
              dokuStatusCheckedAt: new Date().toISOString(),
              dokuStatusRequest: checkBody,
              dokuStatusResponse: dokuBody,
            },
            client_updated_at: new Date().toISOString(),
            confirmed_at:
              status === 'confirmed' ? new Date().toISOString() : null,
            synced_at: new Date().toISOString(),
          },
          {
            onConflict: 'transaction_id',
          },
        )
        .select('*')
        .single();

      transactionRecord = data;
      transactionRecordError = error?.message || null;
    }

    return jsonResponse(
      {
        ok: dokuResponse.ok,
        transactionId,
        status,
        environment,
        doku: dokuBody,
        transactionRecord,
        transactionRecordError,
        error: dokuResponse.ok
          ? null
          : dokuBody?.responseMessage || `DOKU error ${dokuResponse.status}`,
      },
      dokuResponse.ok ? 200 : 502,
    );
  } catch (error) {
    return jsonResponse(
      {
        ok: false,
        error: error instanceof Error ? error.message : 'Unknown error.',
      },
      500,
    );
  }
});
