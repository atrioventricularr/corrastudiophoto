import type {
  CorraBoothSession,
  CorraSessionLifecycleEvent,
} from './types';

export type RecordBoothSessionLifecycleInput = {
  session: CorraBoothSession;
  events?: CorraSessionLifecycleEvent[];
};

export type RecordBoothSessionLifecycleResult = {
  ok: boolean;
  sessionId?: string;
  session?: Record<string, unknown>;
  eventsCount?: number;
  events?: Record<string, unknown>[];
  eventsError?: string | null;
  syncedAt?: string;
  error?: string;
  step?: string;
};

const DEFAULT_RECORD_SESSION_LIFECYCLE_URL =
  'https://uitnzrstkjvwiojbnpwg.supabase.co/functions/v1/record-booth-session-lifecycle';

function getRecordSessionLifecycleUrl(): string {
  return (
    import.meta.env.VITE_RECORD_BOOTH_SESSION_LIFECYCLE_URL ||
    DEFAULT_RECORD_SESSION_LIFECYCLE_URL
  );
}

function getSupabaseAnonKey(): string {
  return (
    import.meta.env.VITE_SUPABASE_ANON_KEY ||
    import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ||
    ''
  );
}

export function isSessionLifecycleSyncConfigured(): boolean {
  return Boolean(getRecordSessionLifecycleUrl() && getSupabaseAnonKey());
}

export async function recordBoothSessionLifecycle(
  input: RecordBoothSessionLifecycleInput,
): Promise<RecordBoothSessionLifecycleResult> {
  const url = getRecordSessionLifecycleUrl();
  const anonKey = getSupabaseAnonKey();

  if (!url || !anonKey) {
    return {
      ok: false,
      sessionId: input.session.id,
      error:
        'Missing VITE_RECORD_BOOTH_SESSION_LIFECYCLE_URL or VITE_SUPABASE_ANON_KEY.',
      step: 'client_config',
    };
  }

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${anonKey}`,
        apikey: anonKey,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        session: input.session,
        events: input.events || [],
      }),
    });

    const body = (await response.json().catch(() => null)) as
      | RecordBoothSessionLifecycleResult
      | null;

    if (!response.ok) {
      return {
        ok: false,
        sessionId: input.session.id,
        error:
          body?.error ||
          `Record booth session lifecycle failed with status ${response.status}`,
        step: body?.step || 'http_error',
      };
    }

    return (
      body || {
        ok: false,
        sessionId: input.session.id,
        error: 'Empty record booth session lifecycle response.',
        step: 'empty_response',
      }
    );
  } catch (error) {
    return {
      ok: false,
      sessionId: input.session.id,
      error:
        error instanceof Error
          ? error.message
          : 'Unknown session lifecycle sync error.',
      step: 'network_error',
    };
  }
}
