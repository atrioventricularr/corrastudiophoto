#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - Phase 5A Core DB"
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

echo ""
echo "Checking repository structure..."

[ -f "package.json" ] || fail "Root package.json not found. Run this from repo root."
[ -d "infra/supabase/migrations" ] || mkdir -p infra/supabase/migrations

echo "Repository structure OK."

echo ""
echo "Creating backup..."

BACKUP_DIR="infra/.phase-backups/phase-5a-core-db-before-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

if [ -d "infra/supabase/migrations" ]; then
  cp -a infra/supabase/migrations "$BACKUP_DIR/migrations"
fi

echo "Backup stored at: $BACKUP_DIR"

echo ""
echo "Writing Phase 5A migrations..."

write_file "infra/supabase/migrations/001_enable_extensions.sql" <<'SQL'
-- Corra Booth
-- 001_enable_extensions.sql

create extension if not exists "pgcrypto";
SQL

write_file "infra/supabase/migrations/002_create_enums.sql" <<'SQL'
-- Corra Booth
-- 002_create_enums.sql

do $$
begin
  if not exists (select 1 from pg_type where typname = 'license_status') then
    create type public.license_status as enum (
      'PENDING',
      'ACTIVE',
      'EXPIRED',
      'SUSPENDED',
      'CANCELLED'
    );
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'license_billing_cycle') then
    create type public.license_billing_cycle as enum (
      'MONTHLY',
      'YEARLY',
      'TRIAL',
      'LIFETIME'
    );
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'booth_run_mode') then
    create type public.booth_run_mode as enum (
      'SESSION',
      'SINGLE'
    );
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'photo_session_status') then
    create type public.photo_session_status as enum (
      'IDLE',
      'SELECTING_LAYOUT',
      'SELECTING_TEMPLATE',
      'WAITING_PAYMENT',
      'CAPTURING',
      'COMPOSING',
      'UPLOADING',
      'PRINTING',
      'COMPLETED',
      'FAILED',
      'CANCELLED'
    );
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'photo_asset_kind') then
    create type public.photo_asset_kind as enum (
      'RAW_CAPTURE',
      'FINAL_FRAME',
      'GIF'
    );
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'license_activation_action') then
    create type public.license_activation_action as enum (
      'ACTIVATED',
      'VERIFIED',
      'DEACTIVATED',
      'DEVICE_LIMIT_REACHED'
    );
  end if;
end $$;
SQL

write_file "infra/supabase/migrations/003_create_updated_at_function.sql" <<'SQL'
-- Corra Booth
-- 003_create_updated_at_function.sql

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
SQL

write_file "infra/supabase/migrations/004_create_licenses.sql" <<'SQL'
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
SQL

write_file "infra/supabase/migrations/005_create_booth_devices.sql" <<'SQL'
-- Corra Booth
-- 005_create_booth_devices.sql

create table if not exists public.booth_devices (
  id text primary key,

  license_id uuid not null references public.licenses(id) on delete cascade,

  device_fingerprint text not null,
  device_name text,
  platform text not null default 'WINDOWS_ELECTRON',

  last_seen_at timestamptz,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint booth_devices_id_not_empty check (length(trim(id)) > 0),
  constraint booth_devices_fingerprint_not_empty check (length(trim(device_fingerprint)) > 0)
);

create unique index if not exists idx_booth_devices_license_fingerprint
  on public.booth_devices (license_id, device_fingerprint);

create index if not exists idx_booth_devices_license_id
  on public.booth_devices (license_id);

create index if not exists idx_booth_devices_last_seen_at
  on public.booth_devices (last_seen_at);

drop trigger if exists trg_booth_devices_set_updated_at on public.booth_devices;

create trigger trg_booth_devices_set_updated_at
before update on public.booth_devices
for each row
execute function public.set_updated_at();
SQL

write_file "infra/supabase/migrations/006_create_license_activations.sql" <<'SQL'
-- Corra Booth
-- 006_create_license_activations.sql

create table if not exists public.license_activations (
  id uuid primary key default gen_random_uuid(),

  license_id uuid not null references public.licenses(id) on delete cascade,
  device_id text references public.booth_devices(id) on delete set null,

  action public.license_activation_action not null,

  ip_address text,
  user_agent text,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now()
);

create index if not exists idx_license_activations_license_id
  on public.license_activations (license_id);

create index if not exists idx_license_activations_device_id
  on public.license_activations (device_id);

create index if not exists idx_license_activations_created_at
  on public.license_activations (created_at);
SQL

write_file "infra/supabase/migrations/007_create_photo_sessions.sql" <<'SQL'
-- Corra Booth
-- 007_create_photo_sessions.sql

create table if not exists public.photo_sessions (
  id text primary key,

  license_id uuid references public.licenses(id) on delete set null,
  device_id text references public.booth_devices(id) on delete set null,

  mode public.booth_run_mode not null,
  status public.photo_session_status not null default 'IDLE',

  frame_count integer not null default 0,
  capture_count integer not null default 0,

  price_charged integer not null default 0,
  currency text not null default 'IDR',

  voucher_code text,

  started_at timestamptz not null default now(),
  completed_at timestamptz,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint photo_sessions_id_not_empty check (length(trim(id)) > 0),
  constraint photo_sessions_frame_count_non_negative check (frame_count >= 0),
  constraint photo_sessions_capture_count_non_negative check (capture_count >= 0),
  constraint photo_sessions_price_non_negative check (price_charged >= 0),
  constraint photo_sessions_completed_after_started check (
    completed_at is null or completed_at >= started_at
  )
);

create index if not exists idx_photo_sessions_license_id
  on public.photo_sessions (license_id);

create index if not exists idx_photo_sessions_device_id
  on public.photo_sessions (device_id);

create index if not exists idx_photo_sessions_mode
  on public.photo_sessions (mode);

create index if not exists idx_photo_sessions_status
  on public.photo_sessions (status);

create index if not exists idx_photo_sessions_started_at
  on public.photo_sessions (started_at);

drop trigger if exists trg_photo_sessions_set_updated_at on public.photo_sessions;

create trigger trg_photo_sessions_set_updated_at
before update on public.photo_sessions
for each row
execute function public.set_updated_at();
SQL

write_file "infra/supabase/migrations/008_create_photo_assets.sql" <<'SQL'
-- Corra Booth
-- 008_create_photo_assets.sql

create table if not exists public.photo_assets (
  id text primary key,

  session_id text not null references public.photo_sessions(id) on delete cascade,
  frame_id text,

  kind public.photo_asset_kind not null,

  storage_bucket text,
  storage_path text,
  public_url text,

  mime_type text not null,

  width integer,
  height integer,
  size_bytes bigint,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),

  constraint photo_assets_id_not_empty check (length(trim(id)) > 0),
  constraint photo_assets_width_positive check (width is null or width > 0),
  constraint photo_assets_height_positive check (height is null or height > 0),
  constraint photo_assets_size_non_negative check (size_bytes is null or size_bytes >= 0)
);

create index if not exists idx_photo_assets_session_id
  on public.photo_assets (session_id);

create index if not exists idx_photo_assets_frame_id
  on public.photo_assets (frame_id);

create index if not exists idx_photo_assets_kind
  on public.photo_assets (kind);

create index if not exists idx_photo_assets_created_at
  on public.photo_assets (created_at);

create unique index if not exists idx_photo_assets_storage_unique
  on public.photo_assets (storage_bucket, storage_path)
  where storage_bucket is not null and storage_path is not null;
SQL

write_file "infra/supabase/migrations/009_create_transactions.sql" <<'SQL'
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
SQL

echo ""
echo "Creating Phase 5A docs..."

write_file "docs/supabase-phase-5a-core-db.md" <<'MD'
# Corra Booth Supabase Phase 5A

Phase 5A creates the core database foundation.

## Created Migrations

- `001_enable_extensions.sql`
- `002_create_enums.sql`
- `003_create_updated_at_function.sql`
- `004_create_licenses.sql`
- `005_create_booth_devices.sql`
- `006_create_license_activations.sql`
- `007_create_photo_sessions.sql`
- `008_create_photo_assets.sql`
- `009_create_transactions.sql`

## Not Included Yet

These are intentionally delayed to Phase 5B and 5C:

- layouts
- templates
- vouchers
- admin_users
- business_settings
- RLS policies
- storage buckets
- seed data

## Important

Do not push to Supabase before all Phase 5 migration files are complete, unless you intentionally want to test the schema incrementally.
MD

echo ""
echo "Verifying generated SQL files..."

SQL_COUNT="$(find infra/supabase/migrations -maxdepth 1 -type f -name "*.sql" | wc -l | tr -d ' ')"

echo "SQL migration count: $SQL_COUNT"

if [ "$SQL_COUNT" -lt 9 ]; then
  fail "Expected at least 9 SQL migration files for Phase 5A."
fi

ls -1 infra/supabase/migrations/*.sql | sort

echo ""
echo "========================================"
echo " Phase 5A completed."
echo "========================================"
echo ""
echo "Next:"
echo "  git add ."
echo "  git commit -m \"feat: add supabase core database migrations\""
echo ""
