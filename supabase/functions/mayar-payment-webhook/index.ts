import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-mayar-signature',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function normalizeStatus(value: unknown) {
  const status = typeof value === 'string' ? value.toLowerCase() : '';

  if (['paid', 'success', 'successful', 'settlement', 'settled', 'completed', 'complete'].includes(status)) return 'paid';
  if (['expired', 'expire', 'cancelled', 'canceled', 'failed', 'deny'].includes(status)) return 'failed';
  if (['pending', 'waiting', 'unpaid', 'created', 'process'].includes(status)) return 'pending';

  return status || 'pending';
}

function pickString(source: Record<string, unknown>, keys: string[]) {
  for (const key of keys) {
    const value = source[key];
    if (typeof value === 'string' && value.trim()) return value.trim();
  }
  return '';
}

serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (request.method !== 'POST') return json({ ok: false, error: 'Method not allowed.' }, 405);

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !serviceRoleKey) throw new Error('Missing Supabase Edge Function env.');

    const payload = (await request.json()) as Record<string, unknown>;
    const data = payload.data && typeof payload.data === 'object'
      ? payload.data as Record<string, unknown>
      : payload;

    const status = normalizeStatus(
      data.status || data.paymentStatus || data.payment_status || payload.status,
    );

    const providerOrderId = pickString(data, [
      'id',
      'paymentId',
      'payment_id',
      'transactionId',
      'transaction_id',
      'invoiceId',
      'invoice_id',
    ]);

    const providerReferenceId = pickString(data, [
      'referenceId',
      'reference_id',
      'externalId',
      'external_id',
    ]);

    const paidAt = status === 'paid'
      ? new Date().toISOString()
      : null;

    const supabase = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false } });

    let query = supabase.from('booth_payment_intents').update({
      status,
      raw_response: payload,
      paid_at: paidAt,
      updated_at: new Date().toISOString(),
    });

    if (providerOrderId) query = query.eq('provider_order_id', providerOrderId);
    else if (providerReferenceId) query = query.eq('provider_reference_id', providerReferenceId);
    else throw new Error('Webhook missing provider id/reference id.');

    await query;

    return json({ ok: true, status, providerOrderId, providerReferenceId });
  } catch (error) {
    return json({ ok: false, error: error instanceof Error ? error.message : 'Unknown error.' }, 400);
  }
});
