import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

type CreateMayarCheckoutRequest = {
  sessionId?: string;
  amount?: number;
  currency?: string;
  description?: string;
  customerName?: string;
  customerEmail?: string;
  customerPhone?: string;
  successRedirectUrl?: string;
  failureRedirectUrl?: string;
  expiresInMinutes?: number;
};

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function cleanString(value: unknown) {
  return typeof value === 'string' ? value.trim() : '';
}

function getAmount(value: unknown) {
  const amount = Number(value);
  if (!Number.isFinite(amount) || amount <= 0) {
    throw new Error('amount must be a positive number.');
  }
  return Math.round(amount);
}

async function callMayar(apiKey: string, body: Record<string, unknown>) {
  const endpoints = [
    'https://api.mayar.id/hl/v1/payment/create',
    'https://api.mayar.id/v1/payment/create',
    'https://api.mayar.id/hl/v1/checkout/create',
  ];

  let lastError = '';

  for (const endpoint of endpoints) {
    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      });

      const text = await response.text();
      let parsed: Record<string, unknown> = {};

      try {
        parsed = text ? JSON.parse(text) : {};
      } catch {
        parsed = { rawText: text };
      }

      if (response.ok) {
        return { endpoint, response: parsed };
      }

      lastError = `${endpoint}: ${response.status} ${text}`;
    } catch (error) {
      lastError = error instanceof Error ? error.message : 'Unknown Mayar request error.';
    }
  }

  throw new Error(lastError || 'Mayar checkout request failed.');
}

function pickString(source: Record<string, unknown>, keys: string[]) {
  for (const key of keys) {
    const value = source[key];
    if (typeof value === 'string' && value.trim()) return value.trim();
  }
  return '';
}

function pickNestedString(source: Record<string, unknown>, keys: string[]) {
  const candidates = [source];
  const data = source.data;
  if (data && typeof data === 'object') candidates.push(data as Record<string, unknown>);

  for (const candidate of candidates) {
    const result = pickString(candidate, keys);
    if (result) return result;
  }

  return '';
}

serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (request.method !== 'POST') return json({ ok: false, error: 'Method not allowed.' }, 405);

  try {
    const mayarApiKey = Deno.env.get('MAYAR_API_KEY') || Deno.env.get('MAYAR_SECRET_KEY');
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!mayarApiKey) throw new Error('Missing MAYAR_API_KEY Edge Function secret.');
    if (!supabaseUrl || !serviceRoleKey) throw new Error('Missing Supabase Edge Function env.');

    const payload = (await request.json()) as CreateMayarCheckoutRequest;
    const amount = getAmount(payload.amount);
    const sessionId = cleanString(payload.sessionId) || crypto.randomUUID();
    const customerName = cleanString(payload.customerName) || 'Corra Booth Customer';
    const customerEmail = cleanString(payload.customerEmail);
    const customerPhone = cleanString(payload.customerPhone);
    const description = cleanString(payload.description) || 'Corra Booth Photo Session';
    const currency = cleanString(payload.currency) || 'IDR';
    const expiresInMinutes = Number(payload.expiresInMinutes || 30);
    const expiresAt = new Date(Date.now() + expiresInMinutes * 60_000).toISOString();
    const orderId = `corra-${sessionId}-${Date.now()}`.replace(/[^a-zA-Z0-9-_]/g, '-');

    const requestBody = {
      name: description,
      description,
      amount,
      currency,
      referenceId: orderId,
      customer: {
        name: customerName,
        email: customerEmail || undefined,
        mobile: customerPhone || undefined,
      },
      redirectUrl: cleanString(payload.successRedirectUrl) || undefined,
      failureRedirectUrl: cleanString(payload.failureRedirectUrl) || undefined,
      expiredAt: expiresAt,
    };

    const mayarResult = await callMayar(mayarApiKey, requestBody);
    const responseBody = mayarResult.response;

    const checkoutUrl = pickNestedString(responseBody, [
      'checkoutUrl',
      'checkout_url',
      'paymentUrl',
      'payment_url',
      'url',
      'link',
    ]);

    const providerOrderId = pickNestedString(responseBody, [
      'id',
      'paymentId',
      'payment_id',
      'transactionId',
      'transaction_id',
      'invoiceId',
      'invoice_id',
      'referenceId',
      'reference_id',
    ]) || orderId;

    const supabase = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false } });

    await supabase.from('booth_payment_intents').insert({
      session_id: sessionId,
      provider: 'MAYAR_CHECKOUT',
      status: 'pending',
      amount,
      currency,
      customer_name: customerName,
      customer_email: customerEmail || null,
      customer_phone: customerPhone || null,
      provider_order_id: providerOrderId,
      provider_reference_id: orderId,
      checkout_url: checkoutUrl || null,
      raw_request: requestBody,
      raw_response: { endpoint: mayarResult.endpoint, response: responseBody },
      expires_at: expiresAt,
    });

    return json({
      ok: true,
      provider: 'MAYAR_CHECKOUT',
      sessionId,
      amount,
      currency,
      status: 'pending',
      providerOrderId,
      providerReferenceId: orderId,
      checkoutUrl,
      expiresAt,
      raw: responseBody,
    });
  } catch (error) {
    return json({ ok: false, error: error instanceof Error ? error.message : 'Unknown error.' }, 400);
  }
});
