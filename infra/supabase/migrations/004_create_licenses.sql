-- Corra Booth
-- 004_create_licenses.sql

create table if not exists public.licenses (
  id uuid primary key default gen_random_uuid(),

  license_code text not null unique,
  owner_email text not null,
  owner_name text,

  status public.license_status not null default 'PENDING',
  billing_cycle public.license_billing_cycle not null default 'MONTHLY',

  mayar_customer_id text,
  mayar_transaction_id text,
  mayar_subscription_id text,

  active_from timestamptz not null default now(),
  active_until timestamptz,

  max_devices integer not null default 1,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint licenses_owner_email_not_empty check (length(trim(owner_email)) > 0),
  constraint licenses_license_code_not_empty check (length(trim(license_code)) > 0),
  constraint licenses_max_devices_positive check (max_devices > 0),
  constraint licenses_active_until_after_active_from check (
    active_until is null or active_until > active_from
  )
);

create index if not exists idx_licenses_license_code
  on public.licenses (license_code);

create index if not exists idx_licenses_owner_email
  on public.licenses (lower(owner_email));

create index if not exists idx_licenses_status
  on public.licenses (status);

create index if not exists idx_licenses_active_until
  on public.licenses (active_until);

drop trigger if exists trg_licenses_set_updated_at on public.licenses;

create trigger trg_licenses_set_updated_at
before update on public.licenses
for each row
execute function public.set_updated_at();
