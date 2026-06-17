import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

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

type StatusPayload = {
  transactionId?: string;
};

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
    const payload = (await request.json()) as StatusPayload;
    const transactionId = payload.transactionId?.trim();

    if (!transactionId) {
      return jsonResponse(
        {
          ok: false,
          error: 'Missing transactionId.',
        },
        400,
      );
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse(
        {
          ok: false,
          error:
            'Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in function env.',
        },
        500,
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        persistSession: false,
      },
    });

    const { data, error } = await supabase
      .from('booth_payment_transactions')
      .select(
        [
          'transaction_id',
          'provider',
          'status',
          'amount_idr',
          'currency',
          'merchant_name',
          'voucher_code',
          'confirmation_code',
          'failure_reason',
          'cancel_reason',
          'confirmed_at',
          'cancelled_at',
          'synced_at',
          'updated_at',
          'metadata',
        ].join(','),
      )
      .eq('transaction_id', transactionId)
      .maybeSingle();

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

    if (!data) {
      return jsonResponse({
        ok: true,
        found: false,
        transactionId,
        status: 'not_found',
      });
    }

    return jsonResponse({
      ok: true,
      found: true,
      transactionId,
      status: data.status,
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
