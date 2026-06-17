#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8D1A - Create DOKU QRIS Function"
echo "========================================"

mkdir -p supabase/functions/create-doku-qris

cat > supabase/functions/create-doku-qris/index.ts <<'TS'
type CreateDokuQrisPayload = {
  transactionId?: string;
  amountIdr?: number;
  merchantId?: string;
  terminalId?: string;
  environment?: 'sandbox' | 'production';
  validityMinutes?: number;
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

function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = '';

  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }

  return btoa(binary);
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

function minifyJson(value: unknown): string {
  return JSON.stringify(value);
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

async function createQrisSignature(params: {
  method: string;
  path: string;
  accessToken: string;
  requestBody: unknown;
  timestamp: string;
  clientSecret: string;
}) {
  const bodyHash = await sha256HexLower(minifyJson(params.requestBody));
  const stringToSign = [
    params.method,
    params.path,
    params.accessToken,
    bodyHash,
    params.timestamp,
  ].join(':');

  const signature = await hmacSha512Base64(
    params.clientSecret,
    stringToSign,
  );

  return signature;
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
    const payload = (await request.json()) as CreateDokuQrisPayload;

    const environment = payload.environment || 'sandbox';
    const baseUrl = getDokuBaseUrl(environment);

    const clientId = Deno.env.get('DOKU_CLIENT_ID');
    const clientSecret = Deno.env.get('DOKU_CLIENT_SECRET');
    const privateKey = Deno.env.get('DOKU_PRIVATE_KEY');

    const merchantId =
      payload.merchantId || Deno.env.get('DOKU_MERCHANT_ID') || '';
    const terminalId =
      payload.terminalId || Deno.env.get('DOKU_TERMINAL_ID') || 'A01';

    if (!clientId || !clientSecret || !privateKey || !merchantId) {
      return jsonResponse(
        {
          ok: false,
          error:
            'Missing DOKU env. Required: DOKU_CLIENT_ID, DOKU_CLIENT_SECRET, DOKU_PRIVATE_KEY, DOKU_MERCHANT_ID.',
        },
        500,
      );
    }

    const transactionId =
      payload.transactionId || `CORRA-${crypto.randomUUID()}`.slice(0, 64);

    const amountIdr = Number(payload.amountIdr || 0);

    if (!amountIdr || amountIdr < 1) {
      return jsonResponse(
        { ok: false, error: 'amountIdr must be greater than 0.' },
        400,
      );
    }

    const accessToken = await getB2BToken({
      baseUrl,
      clientId,
      privateKey,
    });

    const path = '/snap-adapter/b2b/v1.0/qr/qr-mpm-generate';
    const timestamp = createTimestampJakarta();
    const externalId = createExternalId();

    const validityMinutes = payload.validityMinutes || 15;
    const validityPeriod = new Date(
      Date.now() + validityMinutes * 60 * 1000,
    )
      .toISOString()
      .replace('Z', '+00:00');

    const qrisBody = {
      partnerReferenceNo: transactionId,
      amount: {
        value: `${amountIdr}.00`,
        currency: 'IDR',
      },
      merchantId,
      terminalId,
      validityPeriod,
      additionalInfo: {
        postalCode: '12190',
        feeType: 'NO_FEE',
      },
    };

    const signature = await createQrisSignature({
      method: 'POST',
      path,
      accessToken,
      requestBody: qrisBody,
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
      body: JSON.stringify(qrisBody),
    });

    const dokuBody = await dokuResponse.json().catch(() => null);

    return jsonResponse(
      {
        ok: dokuResponse.ok,
        transactionId,
        environment,
        request: {
          partnerReferenceNo: transactionId,
          amountIdr,
          merchantId,
          terminalId,
          validityPeriod,
        },
        doku: dokuBody,
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
TS

echo ""
echo "Created:"
echo "- supabase/functions/create-doku-qris/index.ts"
echo ""
echo "Phase 8D1A completed."
