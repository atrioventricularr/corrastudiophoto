#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8E3A - Session Lifecycle Supabase Migration"
echo "========================================"

mkdir -p supabase/migrations

cat > supabase/migrations/021_booth_session_lifecycle.sql <<'SQL'
create table if not exists public.booth_sessions (
  id uuid primary key default gen_random_uuid(),
  session_id text not null unique,
  status text not null default 'session_created',

  payment_transaction_id text null,
  payment_confirmation_code text null,
  voucher_code text null,

  layout_id text null,
  template_id text null,
  capture_count integer not null default 0,

  final_asset_url text null,
  gif_asset_url text null,
  error_message text null,

  metadata jsonb not null default '{}'::jsonb,

  client_created_at timestamptz null,
  client_updated_at timestamptz null,
  completed_at timestamptz null,
  cancelled_at timestamptz null,
  synced_at timestamptz null,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists booth_sessions_session_id_idx
  on public.booth_sessions (session_id);

create index if not exists booth_sessions_status_idx
  on public.booth_sessions (status);

create index if not exists booth_sessions_created_at_idx
  on public.booth_sessions (created_at desc);

create index if not exists booth_sessions_payment_transaction_id_idx
  on public.booth_sessions (payment_transaction_id);

create table if not exists public.booth_session_lifecycle_events (
  id uuid primary key default gen_random_uuid(),
  event_id text not null unique,
  session_id text not null,

  from_status text null,
  to_status text not null,
  reason text null,

  metadata jsonb not null default '{}'::jsonb,

  client_created_at timestamptz null,
  synced_at timestamptz null,

  created_at timestamptz not null default now(),

  constraint booth_session_lifecycle_events_session_fk
    foreign key (session_id)
    references public.booth_sessions (session_id)
    on delete cascade
);

create index if not exists booth_session_lifecycle_events_session_id_idx
  on public.booth_session_lifecycle_events (session_id);

create index if not exists booth_session_lifecycle_events_created_at_idx
  on public.booth_session_lifecycle_events (created_at desc);

alter table public.booth_sessions enable row level security;
alter table public.booth_session_lifecycle_events enable row level security;

drop policy if exists "Service role can manage booth sessions"
  on public.booth_sessions;

create policy "Service role can manage booth sessions"
  on public.booth_sessions
  for all
  using (auth.role() = 'service_role')
  with check (auth.role() = 'service_role');

drop policy if exists "Service role can manage booth session lifecycle events"
  on public.booth_session_lifecycle_events;

create policy "Service role can manage booth session lifecycle events"
  on public.booth_session_lifecycle_events
  for all
  using (auth.role() = 'service_role')
  with check (auth.role() = 'service_role');

create or replace function public.set_booth_sessions_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists booth_sessions_set_updated_at
  on public.booth_sessions;

create trigger booth_sessions_set_updated_at
before update on public.booth_sessions
for each row
execute function public.set_booth_sessions_updated_at();
SQL

echo ""
echo "Created:"
echo "- supabase/migrations/021_booth_session_lifecycle.sql"
echo ""
echo "Phase 8E3A completed."
