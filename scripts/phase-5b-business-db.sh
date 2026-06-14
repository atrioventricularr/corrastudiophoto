#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - Phase 5B Business DB"
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

append_gitignore_if_missing() {
  local pattern="$1"

  touch .gitignore

  if grep -qxF "$pattern" .gitignore; then
    echo "SKIP .gitignore pattern exists: $pattern"
  else
    printf "\n%s\n" "$pattern" >> .gitignore
    echo "ADD .gitignore pattern: $pattern"
  fi
}

echo ""
echo "Checking repository structure..."

[ -f "package.json" ] || fail "Root package.json not found. Run this from repo root."
[ -d "infra/supabase/migrations" ] || fail "infra/supabase/migrations not found."
[ -f "infra/supabase/migrations/009_create_transactions.sql" ] || fail "Phase 5A migration 009_create_transactions.sql not found. Run Phase 5A first."

echo "Repository structure OK."

echo ""
echo "Ignoring phase backup folders..."

append_gitignore_if_missing "infra/.phase-backups/"
append_gitignore_if_missing "packages/.phase-backups/"

echo ""
echo "Creating external backup..."

BACKUP_DIR="/tmp/corra-booth-phase-5b-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

cp -a infra/supabase/migrations "$BACKUP_DIR/migrations"

echo "Backup stored outside repo at: $BACKUP_DIR"

echo ""
echo "Writing Phase 5B migrations..."

write_file "infra/supabase/migrations/010_create_business_enums.sql" <<'SQL'
-- Corra Booth
-- 010_create_business_enums.sql

do $$
begin
  if not exists (select 1 from pg_type where typname = 'voucher_discount_type') then
    create type public.voucher_discount_type as enum (
      'PERCENTAGE',
      'FIXED_AMOUNT',
      'FREE_SESSION'
    );
  end if;
end $$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'admin_role') then
    create type public.admin_role as enum (
      'OWNER',
      'ADMIN',
      'STAFF'
    );
  end if;
end $$;
SQL

write_file "infra/supabase/migrations/011_create_layouts_templates.sql" <<'SQL'
-- Corra Booth
-- 011_create_layouts_templates.sql

create table if not exists public.layouts (
  id text primary key,

  name text not null,

  canvas_width integer not null,
  canvas_height integer not null,

  slot_count integer not null,
  slots jsonb not null default '[]'::jsonb,

  is_active boolean not null default true,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint layouts_id_not_empty check (length(trim(id)) > 0),
  constraint layouts_name_not_empty check (length(trim(name)) > 0),
  constraint layouts_canvas_width_positive check (canvas_width > 0),
  constraint layouts_canvas_height_positive check (canvas_height > 0),
  constraint layouts_slot_count_valid check (slot_count between 2 and 8),
  constraint layouts_slots_is_array check (jsonb_typeof(slots) = 'array')
);

create index if not exists idx_layouts_is_active
  on public.layouts (is_active);

create index if not exists idx_layouts_slot_count
  on public.layouts (slot_count);

drop trigger if exists trg_layouts_set_updated_at on public.layouts;

create trigger trg_layouts_set_updated_at
before update on public.layouts
for each row
execute function public.set_updated_at();

create table if not exists public.templates (
  id text primary key,

  layout_id text not null references public.layouts(id) on delete cascade,

  name text not null,

  background_storage_path text,
  background_public_url text,

  canvas_width integer not null,
  canvas_height integer not null,

  is_active boolean not null default true,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint templates_id_not_empty check (length(trim(id)) > 0),
  constraint templates_name_not_empty check (length(trim(name)) > 0),
  constraint templates_canvas_width_positive check (canvas_width > 0),
  constraint templates_canvas_height_positive check (canvas_height > 0)
);

create index if not exists idx_templates_layout_id
  on public.templates (layout_id);

create index if not exists idx_templates_is_active
  on public.templates (is_active);

drop trigger if exists trg_templates_set_updated_at on public.templates;

create trigger trg_templates_set_updated_at
before update on public.templates
for each row
execute function public.set_updated_at();
SQL

write_file "infra/supabase/migrations/012_create_vouchers_admin_business_settings.sql" <<'SQL'
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
SQL

write_file "infra/supabase/migrations/013_create_admin_helper_functions.sql" <<'SQL'
-- Corra Booth
-- 013_create_admin_helper_functions.sql

create or replace function public.is_corra_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_users
    where user_id = auth.uid()
      and is_active = true
      and role in ('OWNER', 'ADMIN')
  );
$$;

create or replace function public.is_corra_staff()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_users
    where user_id = auth.uid()
      and is_active = true
      and role in ('OWNER', 'ADMIN', 'STAFF')
  );
$$;
SQL

echo ""
echo "Creating Phase 5B docs..."

write_file "docs/supabase-phase-5b-business-db.md" <<'MD'
# Corra Booth Supabase Phase 5B

Phase 5B creates business-side database tables.

## Created Migrations

- `010_create_business_enums.sql`
- `011_create_layouts_templates.sql`
- `012_create_vouchers_admin_business_settings.sql`
- `013_create_admin_helper_functions.sql`

## Created Tables

- `layouts`
- `templates`
- `vouchers`
- `admin_users`
- `business_settings`

## Created Helper Functions

- `public.is_corra_admin()`
- `public.is_corra_staff()`

## Not Included Yet

These are intentionally delayed to Phase 5C:

- RLS policies
- Storage buckets
- Storage policies
- Default layout seed data

## Important

The first admin still needs to be bootstrapped manually later after Supabase Auth user creation.
MD

echo ""
echo "Verifying generated SQL files..."

SQL_COUNT="$(find infra/supabase/migrations -maxdepth 1 -type f -name "*.sql" | wc -l | tr -d ' ')"

echo "SQL migration count: $SQL_COUNT"

if [ "$SQL_COUNT" -lt 13 ]; then
  fail "Expected at least 13 SQL migration files after Phase 5B."
fi

for file in \
  "infra/supabase/migrations/010_create_business_enums.sql" \
  "infra/supabase/migrations/011_create_layouts_templates.sql" \
  "infra/supabase/migrations/012_create_vouchers_admin_business_settings.sql" \
  "infra/supabase/migrations/013_create_admin_helper_functions.sql"
do
  [ -f "$file" ] || fail "Missing file: $file"
done

ls -1 infra/supabase/migrations/*.sql | sort

echo ""
echo "========================================"
echo " Phase 5B completed."
echo "========================================"
echo ""
echo "Next:"
echo "  git add ."
echo "  git commit -m \"feat: add supabase business database migrations\""
echo ""
