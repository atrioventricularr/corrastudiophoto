import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

type CheckStatusRequest = {
  providerOrderId?: string;
  providerReferenceId?: string;
  sessionId?: string;
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

function normalizeStatus(value: unknown) {
  const status = typeof value === 'string' ? value.toLowerCase() : '';

  if (['paid', 'success', 'successful', 'settlement', 'settled', 'completed', 'complete'].includes(status)) {
    return 'paid';
  }

  if (['expired', 'expire', 'cancelled', 'canceled', 'failed', 'deny'].includes(status)) {
    return 'failed';
  }

  if (['pending', 'waiting', 'unpaid', 'created', 'process'].includes(status)) {
    return 'pending';
  }

  return status || 'pending';
}

function pickStatus(source: Record<string, unknown>) {
  const candidates = [source];
  const data = source.data;
  if (data && typeof data === 'object') candidates.push(data as Record<string, unknown>);

  for (const candidate of candidates) {
    for (const key of ['status', 'paymentStatus', 'payment_status', 'transactionStatus', 'transaction_status']) {
      const value = candidate[key];
      if (typeof value === 'string' && value.trim()) return normalizeStatus(value);
    }
  }

  return 'pending';
}

async function fetchMayarStatus(apiKey: string, id: string) {
  const endpoints = [
    `https://api.mayar.id/hl/v1/payment/${encodeURIComponent(id)}`,
    `https://api.mayar.id/v1/payment/${encodeURIComponent(id)}`,
    `https://api.mayar.id/hl/v1/transaction/${encodeURIComponent(id)}`,
    `https://api.mayar.id/v1/transaction/${encodeURIComponent(id)}`,
  ];

  let lastError = '';

  for (const endpoint of endpoints) {
    try {
      const response = await fetch(endpoint, {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
      });

      const text = await response.text();
      let parsed: Record<string, unknown> = {};

      try {
        parsed = text ? JSON.parse(text) : {};
      } catch {
        parsed = { rawText: text };
      }

      if (response.ok) return { endpoint, response: parsed };
      lastError = `${endpoint}: ${response.status} ${text}`;
    } catch (error) {
      lastError = error instanceof Error ? error.message : 'Unknown Mayar status error.';
    }
  }

  throw new Error(lastError || 'Mayar status request failed.');
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

    const payload = (await request.json()) as CheckStatusRequest;
    const providerOrderId = cleanString(payload.providerOrderId);
    const providerReferenceId = cleanString(payload.providerReferenceId);
    const sessionId = cleanString(payload.sessionId);
    const lookupId = providerOrderId || providerReferenceId || sessionId;

    if (!lookupId) throw new Error('providerOrderId, providerReferenceId, or sessionId is required.');

    const mayarResult = await fetchMayarStatus(mayarApiKey, lookupId);
    const status = pickStatus(mayarResult.response);
    const paidAt = status === 'paid' ? new Date().toISOString() : null;

    const supabase = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false } });

    let query = supabase.from('booth_payment_intents').update({
      status,
      raw_response: { statusEndpoint: mayarResult.endpoint, statusResponse: mayarResult.response },
      paid_at: paidAt,
      updated_at: new Date().toISOString(),
    });

    if (providerOrderId) query = query.eq('provider_order_id', providerOrderId);
    else if (providerReferenceId) query = query.eq('provider_reference_id', providerReferenceId);
    else query = query.eq('session_id', sessionId);

    await query;

    return json({
      ok: true,
      provider: 'MAYAR_CHECKOUT',
      status,
      paidAt,
      providerOrderId,
      providerReferenceId,
      sessionId,
      raw: mayarResult.response,
    });
  } catch (error) {
    return json({ ok: false, error: error instanceof Error ? error.message : 'Unknown error.' }, 400);
  }
});
