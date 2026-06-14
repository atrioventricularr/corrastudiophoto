-- Corra Booth
-- 012_create_vouchers_admin_business_settings.sql

create table if not exists public.vouchers (
  id text primary key,

  code text not null unique,

  discount_type public.voucher_discount_type not null,
  discount_value integer not null default 0,

  max_usage integer,
  usage_count integer not null default 0,

  starts_at timestamptz,
  expires_at timestamptz,

  is_active boolean not null default true,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint vouchers_id_not_empty check (length(trim(id)) > 0),
  constraint vouchers_code_not_empty check (length(trim(code)) > 0),
  constraint vouchers_discount_value_non_negative check (discount_value >= 0),
  constraint vouchers_usage_count_non_negative check (usage_count >= 0),
  constraint vouchers_max_usage_positive check (max_usage is null or max_usage > 0),
  constraint vouchers_expires_after_starts check (
    expires_at is null or starts_at is null or expires_at > starts_at
  )
);

create index if not exists idx_vouchers_code
  on public.vouchers (upper(code));

create index if not exists idx_vouchers_is_active
  on public.vouchers (is_active);

drop trigger if exists trg_vouchers_set_updated_at on public.vouchers;

create trigger trg_vouchers_set_updated_at
before update on public.vouchers
for each row
execute function public.set_updated_at();

create table if not exists public.admin_users (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null unique references auth.users(id) on delete cascade,

  full_name text,
  role public.admin_role not null default 'STAFF',
  is_active boolean not null default true,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_admin_users_user_id
  on public.admin_users (user_id);

create index if not exists idx_admin_users_role
  on public.admin_users (role);

create index if not exists idx_admin_users_is_active
  on public.admin_users (is_active);

drop trigger if exists trg_admin_users_set_updated_at on public.admin_users;

create trigger trg_admin_users_set_updated_at
before update on public.admin_users
for each row
execute function public.set_updated_at();

create table if not exists public.business_settings (
  id text primary key default 'default',

  business_name text not null default 'Corra Booth',
  currency text not null default 'IDR',

  price_per_session integer not null default 0,
  default_print_copies integer not null default 1,

  qris_storage_path text,
  qris_public_url text,

  download_page_base_url text,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint business_settings_id_default check (id = 'default'),
  constraint business_settings_price_non_negative check (price_per_session >= 0),
  constraint business_settings_print_copies_positive check (default_print_copies > 0)
);

drop trigger if exists trg_business_settings_set_updated_at on public.business_settings;

create trigger trg_business_settings_set_updated_at
before update on public.business_settings
for each row
execute function public.set_updated_at();

insert into public.business_settings (id)
values ('default')
on conflict (id) do nothing;
