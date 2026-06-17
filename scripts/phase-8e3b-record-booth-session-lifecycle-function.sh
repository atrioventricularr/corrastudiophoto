#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8E3B - Record Booth Session Lifecycle Function"
echo "========================================"

mkdir -p supabase/functions/record-booth-session-lifecycle

cat > supabase/functions/record-booth-session-lifecycle/index.ts <<'TS'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

type BoothSessionPayload = {
  id: string;
  status: string;
  paymentTransactionId?: string | null;
  paymentConfirmationCode?: string | null;
  voucherCode?: string | null;
  layoutId?: string | null;
  templateId?: string | null;
  captureCount?: number;
  finalAssetUrl?: string | null;
  gifAssetUrl?: string | null;
  errorMessage?: string | null;
  metadata?: Record<string, unknown>;
  createdAt?: string;
  updatedAt?: string;
  completedAt?: string | null;
  cancelledAt?: string | null;
};

type BoothSessionLifecycleEventPayload = {
  id: string;
  sessionId: string;
  fromStatus?: string | null;
  toStatus: string;
  reason?: string | null;
  metadata?: Record<string, unknown>;
  createdAt?: string;
};

type RecordBoothSessionLifecyclePayload = {
  session?: BoothSessionPayload | null;
  events?: BoothSessionLifecycleEventPayload[];
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

function nullableTimestamp(value?: string | null) {
  if (!value) return null;

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return null;
  }

  return date.toISOString();
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
    const payload =
      (await request.json()) as RecordBoothSessionLifecyclePayload;

    if (!payload.session?.id) {
      return jsonResponse(
        {
          ok: false,
          error: 'Missing session.id.',
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
            'Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY runtime env.',
        },
        500,
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        persistSession: false,
      },
    });

    const session = payload.session;
    const now = new Date().toISOString();

    const sessionRow = {
      session_id: session.id,
      status: session.status || 'session_created',

      payment_transaction_id: session.paymentTransactionId || null,
      payment_confirmation_code: session.paymentConfirmationCode || null,
      voucher_code: session.voucherCode || null,

      layout_id: session.layoutId || null,
      template_id: session.templateId || null,
      capture_count: session.captureCount || 0,

      final_asset_url: session.finalAssetUrl || null,
      gif_asset_url: session.gifAssetUrl || null,
      error_message: session.errorMessage || null,

      metadata: session.metadata || {},

      client_created_at: nullableTimestamp(session.createdAt),
      client_updated_at: nullableTimestamp(session.updatedAt),
      completed_at: nullableTimestamp(session.completedAt),
      cancelled_at: nullableTimestamp(session.cancelledAt),
      synced_at: now,
    };

    const { data: savedSession, error: sessionError } = await supabase
      .from('booth_sessions')
      .upsert(sessionRow, {
        onConflict: 'session_id',
      })
      .select('*')
      .single();

    if (sessionError) {
      return jsonResponse(
        {
          ok: false,
          error: sessionError.message,
          step: 'upsert_session',
        },
        500,
      );
    }

    const events = Array.isArray(payload.events) ? payload.events : [];

    const eventRows = events
      .filter((event) => event.id && event.sessionId)
      .map((event) => ({
        event_id: event.id,
        session_id: event.sessionId,
        from_status: event.fromStatus || null,
        to_status: event.toStatus,
        reason: event.reason || null,
        metadata: event.metadata || {},
        client_created_at: nullableTimestamp(event.createdAt),
        synced_at: now,
      }));

    let savedEvents: unknown[] = [];
    let eventsErrorMessage: string | null = null;

    if (eventRows.length > 0) {
      const { data, error } = await supabase
        .from('booth_session_lifecycle_events')
        .upsert(eventRows, {
          onConflict: 'event_id',
        })
        .select('*');

      savedEvents = data || [];
      eventsErrorMessage = error?.message || null;

      if (error) {
        return jsonResponse(
          {
            ok: false,
            error: error.message,
            step: 'upsert_events',
            session: savedSession,
          },
          500,
        );
      }
    }

    return jsonResponse({
      ok: true,
      sessionId: session.id,
      session: savedSession,
      eventsCount: eventRows.length,
      events: savedEvents,
      eventsError: eventsErrorMessage,
      syncedAt: now,
    });
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
echo "- supabase/functions/record-booth-session-lifecycle/index.ts"
echo ""
echo "Phase 8E3B completed."
