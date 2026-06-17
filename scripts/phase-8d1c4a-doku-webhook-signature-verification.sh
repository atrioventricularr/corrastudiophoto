#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8D1C4A - DOKU Webhook Signature"
echo "========================================"

FILE="supabase/functions/doku-payment-notification/index.ts"

[ -f "$FILE" ] || {
  echo "ERROR: doku-payment-notification function not found. Run 8D1C1 first."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("supabase/functions/doku-payment-notification/index.ts")
text = path.read_text()

helper = r'''
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

'''

if "verifyDokuSnapSignature" not in text:
    marker = "function getString(value: unknown): string {"
    text = text.replace(marker, helper + "\n" + marker)

old_parse = """    const payload = (await request.json()) as Record<string, unknown>;"""

new_parse = """    const rawBody = await request.text();
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
    }"""

if old_parse in text:
    text = text.replace(old_parse, new_parse)
else:
    raise SystemExit("Could not find request.json payload parse block.")

old_meta = """        rawNotification: payload,"""

new_meta = """        rawNotification: payload,
        signatureVerification: signatureVerification
          ? {
              valid: signatureVerification.valid,
              reason: signatureVerification.reason,
              stringToSign: signatureVerification.stringToSign,
            }
          : {
              valid: false,
              reason:
                'Signature verification skipped. Set DOKU_VERIFY_WEBHOOK_SIGNATURE=true for production.',
            },"""

if old_meta in text and "signatureVerification:" not in text:
    text = text.replace(old_meta, new_meta)

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Verifying..."

grep -q "verifyDokuSnapSignature" "$FILE" || {
  echo "ERROR: signature verifier missing."
  exit 1
}

grep -q "DOKU_VERIFY_WEBHOOK_SIGNATURE" "$FILE" || {
  echo "ERROR: verification env flag missing."
  exit 1
}

grep -q "Invalid DOKU webhook signature" "$FILE" || {
  echo "ERROR: invalid signature guard missing."
  exit 1
}

echo ""
echo "Phase 8D1C4A completed."
