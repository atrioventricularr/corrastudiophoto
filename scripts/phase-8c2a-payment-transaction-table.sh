#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8C2A - Payment Transaction Table"
echo "========================================"

mkdir -p supabase/migrations
mkdir -p infra/supabase/migrations

cat > supabase/migrations/020_booth_payment_transactions.sql <<'SQL'
create table if not exists public.booth_payment_transactions (
  id uuid primary key default gen_random_uuid(),

  transaction_id text not null unique,
  provider text not null,
  status text not null,

  amount_idr integer not null default 0,
  currency text not null default 'IDR',
  merchant_name text,

  voucher_code text,
  confirmation_code text,
  failure_reason text,
  cancel_reason text,

  device_fingerprint text,
  license_code text,

  source text not null default 'booth-ui',
  metadata jsonb not null default '{}'::jsonb,

  client_created_at timestamptz,
  client_updated_at timestamptz,
  confirmed_at timestamptz,
  cancelled_at timestamptz,

  synced_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_booth_payment_transactions_transaction_id
  on public.booth_payment_transactions(transaction_id);

create index if not exists idx_booth_payment_transactions_status
  on public.booth_payment_transactions(status);

create index if not exists idx_booth_payment_transactions_provider
  on public.booth_payment_transactions(provider);

create index if not exists idx_booth_payment_transactions_created_at
  on public.booth_payment_transactions(created_at desc);

create or replace function public.set_booth_payment_transactions_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_booth_payment_transactions_updated_at
  on public.booth_payment_transactions;

create trigger trg_booth_payment_transactions_updated_at
before update on public.booth_payment_transactions
for each row
execute function public.set_booth_payment_transactions_updated_at();

alter table public.booth_payment_transactions enable row level security;

drop policy if exists "service_role_full_access_booth_payment_transactions"
  on public.booth_payment_transactions;

create policy "service_role_full_access_booth_payment_transactions"
on public.booth_payment_transactions
for all
to service_role
using (true)
with check (true);
SQL

cp supabase/migrations/020_booth_payment_transactions.sql infra/supabase/migrations/020_booth_payment_transactions.sql

echo ""
echo "Created:"
echo "- supabase/migrations/020_booth_payment_transactions.sql"
echo "- infra/supabase/migrations/020_booth_payment_transactions.sql"
echo ""
echo "Phase 8C2A completed."
