-- Corra Booth
-- 009_create_transactions.sql

create table if not exists public.transactions (
  id text primary key,

  session_id text references public.photo_sessions(id) on delete set null,
  license_id uuid references public.licenses(id) on delete set null,

  type text not null,
  message text not null,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),

  constraint transactions_id_not_empty check (length(trim(id)) > 0),
  constraint transactions_type_not_empty check (length(trim(type)) > 0),
  constraint transactions_message_not_empty check (length(trim(message)) > 0)
);

create index if not exists idx_transactions_session_id
  on public.transactions (session_id);

create index if not exists idx_transactions_license_id
  on public.transactions (license_id);

create index if not exists idx_transactions_type
  on public.transactions (type);

create index if not exists idx_transactions_created_at
  on public.transactions (created_at);
