#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - Phase 6A License Foundation"
echo "========================================"

fail() {
  echo ""
  echo "ERROR: $1"
  echo ""
  exit 1
}

write_file() {
  local file_path="$1"
  mkdir -p "$(dirname "$file_path")"
  cat > "$file_path"
  echo "WRITE file: $file_path"
}

append_if_missing() {
  local file_path="$1"
  local pattern="$2"
  local content="$3"

  touch "$file_path"

  if grep -qF "$pattern" "$file_path"; then
    echo "SKIP $file_path already has: $pattern"
  else
    printf "\n%s\n" "$content" >> "$file_path"
    echo "APPEND to $file_path: $pattern"
  fi
}

echo ""
echo "Checking repository..."

[ -f "package.json" ] || fail "Root package.json not found. Run this from repo root."
[ -d "infra/supabase/migrations" ] || fail "infra/supabase/migrations not found."
[ -d "supabase/migrations" ] || fail "supabase/migrations not found. Run Phase 5D first."
[ -f "supabase/config.toml" ] || fail "supabase/config.toml not found. Run Phase 5D first."
[ -f "supabase/migrations/018_seed_default_layouts.sql" ] || fail "Phase 5C migration 018 not found in supabase/migrations."

echo "Repository OK."

echo ""
echo "Writing migration 019..."

write_file "infra/supabase/migrations/019_create_mayar_webhook_events.sql" <<'SQL'
-- Corra Booth
-- 019_create_mayar_webhook_events.sql

create table if not exists public.mayar_webhook_events (
  id uuid primary key default gen_random_uuid(),

  event_id text unique,
  event_type text,
  transaction_id text,

  license_id uuid references public.licenses(id) on delete set null,

  processing_status text not null default 'RECEIVED',
  error_message text,

  payload jsonb not null default '{}'::jsonb,

  received_at timestamptz not null default now(),
  processed_at timestamptz,

  created_at timestamptz not null default now(),

  constraint mayar_webhook_events_status_not_empty check (length(trim(processing_status)) > 0)
);

create index if not exists idx_mayar_webhook_events_event_id
  on public.mayar_webhook_events (event_id);

create index if not exists idx_mayar_webhook_events_transaction_id
  on public.mayar_webhook_events (transaction_id);

create index if not exists idx_mayar_webhook_events_license_id
  on public.mayar_webhook_events (license_id);

create index if not exists idx_mayar_webhook_events_received_at
  on public.mayar_webhook_events (received_at);

alter table public.mayar_webhook_events enable row level security;

drop policy if exists mayar_webhook_events_staff_select on public.mayar_webhook_events;
create policy mayar_webhook_events_staff_select
on public.mayar_webhook_events
for select
to authenticated
using (public.is_corra_staff());

drop policy if exists mayar_webhook_events_admin_all on public.mayar_webhook_events;
create policy mayar_webhook_events_admin_all
on public.mayar_webhook_events
for all
to authenticated
using (public.is_corra_admin())
with check (public.is_corra_admin());
SQL

cp infra/supabase/migrations/019_create_mayar_webhook_events.sql supabase/migrations/

echo ""
echo "Writing shared Edge Function helpers..."

write_file "supabase/functions/_shared/cors.ts" <<'TS'
export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-corra-webhook-secret",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

export function handleCors(req: Request): Response | null {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  return null;
}

export function jsonResponse(
  body: unknown,
  status = 200,
  extraHeaders: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      ...extraHeaders,
      "Content-Type": "application/json",
    },
  });
}
TS

write_file "supabase/functions/_shared/env.ts" <<'TS'
export function getRequiredEnv(name: string): string {
  const value = Deno.env.get(name);

  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value;
}

export function getSupabaseServiceRoleKey(): string {
  return (
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SUPABASE_SECRET_KEY") ??
    ""
  );
}
TS

write_file "supabase/functions/_shared/supabase-admin.ts" <<'TS'
import { createClient } from "npm:@supabase/supabase-js@2";
import { getRequiredEnv, getSupabaseServiceRoleKey } from "./env.ts";

export function createSupabaseAdminClient() {
  const supabaseUrl = getRequiredEnv("SUPABASE_URL");
  const serviceRoleKey = getSupabaseServiceRoleKey();

  if (!serviceRoleKey) {
    throw new Error("Missing SUPABASE_SERVICE_ROLE_KEY or SUPABASE_SECRET_KEY");
  }

  return createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}
TS

write_file "supabase/functions/_shared/object.ts" <<'TS'
type JsonObject = Record<string, unknown>;

export function asObject(value: unknown): JsonObject {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value as JsonObject;
  }

  return {};
}

export function getPath(source: unknown, path: string): unknown {
  const keys = path.split(".");
  let current: unknown = source;

  for (const key of keys) {
    if (!current || typeof current !== "object" || Array.isArray(current)) {
      return undefined;
    }

    current = (current as JsonObject)[key];
  }

  return current;
}

export function findString(source: unknown, paths: string[]): string | null {
  for (const path of paths) {
    const value = getPath(source, path);

    if (typeof value === "string" && value.trim().length > 0) {
      return value.trim();
    }

    if (typeof value === "number" && Number.isFinite(value)) {
      return String(value);
    }
  }

  return null;
}

export function normalizeUpper(value: string | null): string {
  return (value ?? "").trim().toUpperCase();
}
TS

echo ""
echo "Updating .env.example..."

append_if_missing ".env.example" "MAYAR_API_KEY=" 'MAYAR_API_KEY=""
MAYAR_WEBHOOK_SECRET=""
SUPABASE_SERVICE_ROLE_KEY=""'

echo ""
echo "Writing docs..."

write_file "docs/phase-6a-license-foundation.md" <<'MD'
# Phase 6A - License Foundation

Phase 6A adds:

- `mayar_webhook_events` table
- shared CORS helper
- shared env helper
- shared Supabase admin client
- shared object/path helper

## Why `mayar_webhook_events` exists

Mayar webhooks can be retried. This table makes webhook processing idempotent and auditable.

## Next

- Phase 6B: `verify-license` Edge Function
- Phase 6C: `mayar-webhook` Edge Function
- Phase 6D: deploy functions and set secrets
MD

echo ""
echo "Verifying files..."

[ -f "infra/supabase/migrations/019_create_mayar_webhook_events.sql" ] || fail "Missing infra migration 019."
[ -f "supabase/migrations/019_create_mayar_webhook_events.sql" ] || fail "Missing synced migration 019."
[ -f "supabase/functions/_shared/cors.ts" ] || fail "Missing shared cors.ts."
[ -f "supabase/functions/_shared/env.ts" ] || fail "Missing shared env.ts."
[ -f "supabase/functions/_shared/supabase-admin.ts" ] || fail "Missing shared supabase-admin.ts."
[ -f "supabase/functions/_shared/object.ts" ] || fail "Missing shared object.ts."

INFRA_SQL_COUNT="$(find infra/supabase/migrations -maxdepth 1 -type f -name "*.sql" | wc -l | tr -d ' ')"
SYNCED_SQL_COUNT="$(find supabase/migrations -maxdepth 1 -type f -name "*.sql" | wc -l | tr -d ' ')"

echo "Infra SQL count: $INFRA_SQL_COUNT"
echo "Supabase SQL count: $SYNCED_SQL_COUNT"

if [ "$INFRA_SQL_COUNT" -lt 19 ]; then
  fail "Expected at least 19 SQL files in infra/supabase/migrations."
fi

if [ "$SYNCED_SQL_COUNT" -lt 19 ]; then
  fail "Expected at least 19 SQL files in supabase/migrations."
fi

echo ""
echo "========================================"
echo " Phase 6A completed."
echo "========================================"
echo ""
echo "Next:"
echo "  git add ."
echo "  git commit -m \"feat: add license foundation migration and edge helpers\""
echo ""
