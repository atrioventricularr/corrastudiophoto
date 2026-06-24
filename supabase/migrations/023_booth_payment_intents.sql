create table if not exists public.booth_payment_intents (
  id uuid primary key default gen_random_uuid(),
  session_id text,
  provider text not null,
  status text not null default 'created',
  amount integer not null default 0,
  currency text not null default 'IDR',
  customer_name text,
  customer_email text,
  customer_phone text,
  provider_order_id text,
  provider_reference_id text,
  checkout_url text,
  qr_string text,
  qr_image_url text,
  raw_request jsonb not null default '{}'::jsonb,
  raw_response jsonb not null default '{}'::jsonb,
  paid_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists booth_payment_intents_session_id_idx
  on public.booth_payment_intents (session_id);

create index if not exists booth_payment_intents_provider_order_idx
  on public.booth_payment_intents (provider, provider_order_id);

create index if not exists booth_payment_intents_status_idx
  on public.booth_payment_intents (status);

alter table public.booth_payment_intents enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'booth_payment_intents'
      and policyname = 'Service role can manage booth payment intents'
  ) then
    create policy "Service role can manage booth payment intents"
      on public.booth_payment_intents
      for all
      using (auth.role() = 'service_role')
      with check (auth.role() = 'service_role');
  end if;
end $$;
