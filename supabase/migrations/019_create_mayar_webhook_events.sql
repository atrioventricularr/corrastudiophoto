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
