#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - Phase 5C Security Storage Seed"
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
[ -f "infra/supabase/migrations/013_create_admin_helper_functions.sql" ] || fail "Phase 5B migration not found. Run Phase 5B first."

echo "Repository structure OK."

echo ""
echo "Ignoring backup folders..."

append_gitignore_if_missing "infra/.phase-backups/"
append_gitignore_if_missing "packages/.phase-backups/"

echo ""
echo "Creating backup outside repo..."

BACKUP_DIR="/tmp/corra-booth-phase-5c-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -a infra/supabase/migrations "$BACKUP_DIR/migrations"

echo "Backup stored at: $BACKUP_DIR"

echo ""
echo "Writing Phase 5C migrations..."

write_file "infra/supabase/migrations/014_enable_rls.sql" <<'SQL'
-- Corra Booth
-- 014_enable_rls.sql

alter table public.licenses enable row level security;
alter table public.booth_devices enable row level security;
alter table public.license_activations enable row level security;
alter table public.photo_sessions enable row level security;
alter table public.photo_assets enable row level security;
alter table public.transactions enable row level security;
alter table public.layouts enable row level security;
alter table public.templates enable row level security;
alter table public.vouchers enable row level security;
alter table public.admin_users enable row level security;
alter table public.business_settings enable row level security;
SQL

write_file "infra/supabase/migrations/015_create_rls_policies.sql" <<'SQL'
-- Corra Booth
-- 015_create_rls_policies.sql

-- Admin users
drop policy if exists admin_users_select_own on public.admin_users;
create policy admin_users_select_own
on public.admin_users
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists admin_users_admin_select_all on public.admin_users;
create policy admin_users_admin_select_all
on public.admin_users
for select
to authenticated
using (public.is_corra_admin());

drop policy if exists admin_users_admin_all on public.admin_users;
create policy admin_users_admin_all
on public.admin_users
for all
to authenticated
using (public.is_corra_admin())
with check (public.is_corra_admin());

-- Private admin-managed tables
do $$
declare
  tbl text;
begin
  foreach tbl in array array[
    'licenses',
    'booth_devices',
    'license_activations',
    'photo_sessions',
    'photo_assets',
    'transactions',
    'vouchers',
    'business_settings'
  ]
  loop
    execute format('drop policy if exists %I on public.%I', tbl || '_staff_select', tbl);
    execute format(
      'create policy %I on public.%I for select to authenticated using (public.is_corra_staff())',
      tbl || '_staff_select',
      tbl
    );

    execute format('drop policy if exists %I on public.%I', tbl || '_admin_all', tbl);
    execute format(
      'create policy %I on public.%I for all to authenticated using (public.is_corra_admin()) with check (public.is_corra_admin())',
      tbl || '_admin_all',
      tbl
    );
  end loop;
end $$;

-- Public-readable active layouts
drop policy if exists layouts_public_select_active on public.layouts;
create policy layouts_public_select_active
on public.layouts
for select
to anon, authenticated
using (is_active = true);

drop policy if exists layouts_admin_all on public.layouts;
create policy layouts_admin_all
on public.layouts
for all
to authenticated
using (public.is_corra_admin())
with check (public.is_corra_admin());

-- Public-readable active templates
drop policy if exists templates_public_select_active on public.templates;
create policy templates_public_select_active
on public.templates
for select
to anon, authenticated
using (is_active = true);

drop policy if exists templates_admin_all on public.templates;
create policy templates_admin_all
on public.templates
for all
to authenticated
using (public.is_corra_admin())
with check (public.is_corra_admin());
SQL

write_file "infra/supabase/migrations/016_create_storage_buckets.sql" <<'SQL'
-- Corra Booth
-- 016_create_storage_buckets.sql

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values
  (
    'raw-photos',
    'raw-photos',
    false,
    15728640,
    array['image/png', 'image/jpeg', 'image/webp']::text[]
  ),
  (
    'final-frames',
    'final-frames',
    false,
    15728640,
    array['image/png', 'image/jpeg', 'image/webp']::text[]
  ),
  (
    'gifs',
    'gifs',
    false,
    31457280,
    array['image/gif']::text[]
  ),
  (
    'templates',
    'templates',
    true,
    15728640,
    array['image/png', 'image/jpeg', 'image/webp']::text[]
  ),
  (
    'qris',
    'qris',
    false,
    10485760,
    array['image/png', 'image/jpeg', 'image/webp']::text[]
  )
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
SQL

write_file "infra/supabase/migrations/017_create_storage_policies.sql" <<'SQL'
-- Corra Booth
-- 017_create_storage_policies.sql

drop policy if exists storage_templates_public_read on storage.objects;
create policy storage_templates_public_read
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'templates');

drop policy if exists storage_staff_read_qris on storage.objects;
create policy storage_staff_read_qris
on storage.objects
for select
to authenticated
using (
  bucket_id = 'qris'
  and public.is_corra_staff()
);

drop policy if exists storage_admin_manage_template_qris on storage.objects;
create policy storage_admin_manage_template_qris
on storage.objects
for all
to authenticated
using (
  bucket_id in ('templates', 'qris')
  and public.is_corra_admin()
)
with check (
  bucket_id in ('templates', 'qris')
  and public.is_corra_admin()
);

drop policy if exists storage_staff_read_photo_assets on storage.objects;
create policy storage_staff_read_photo_assets
on storage.objects
for select
to authenticated
using (
  bucket_id in ('raw-photos', 'final-frames', 'gifs')
  and public.is_corra_staff()
);

drop policy if exists storage_admin_manage_photo_assets on storage.objects;
create policy storage_admin_manage_photo_assets
on storage.objects
for all
to authenticated
using (
  bucket_id in ('raw-photos', 'final-frames', 'gifs')
  and public.is_corra_admin()
)
with check (
  bucket_id in ('raw-photos', 'final-frames', 'gifs')
  and public.is_corra_admin()
);
SQL

write_file "infra/supabase/migrations/018_seed_default_layouts.sql" <<'SQL'
-- Corra Booth
-- 018_seed_default_layouts.sql

insert into public.layouts (
  id,
  name,
  canvas_width,
  canvas_height,
  slot_count,
  slots,
  is_active
)
values
  (
    'layout-4-portrait',
    '4 Photo Portrait',
    1200,
    1800,
    4,
    '[
      {"slotIndex":0,"x":120,"y":140,"width":460,"height":620,"rotationDeg":0,"borderRadius":24,"objectFit":"cover"},
      {"slotIndex":1,"x":620,"y":140,"width":460,"height":620,"rotationDeg":0,"borderRadius":24,"objectFit":"cover"},
      {"slotIndex":2,"x":120,"y":820,"width":460,"height":620,"rotationDeg":0,"borderRadius":24,"objectFit":"cover"},
      {"slotIndex":3,"x":620,"y":820,"width":460,"height":620,"rotationDeg":0,"borderRadius":24,"objectFit":"cover"}
    ]'::jsonb,
    true
  ),
  (
    'layout-6-portrait',
    '6 Photo Portrait',
    1200,
    1800,
    6,
    '[
      {"slotIndex":0,"x":90,"y":120,"width":320,"height":430,"rotationDeg":0,"borderRadius":20,"objectFit":"cover"},
      {"slotIndex":1,"x":440,"y":120,"width":320,"height":430,"rotationDeg":0,"borderRadius":20,"objectFit":"cover"},
      {"slotIndex":2,"x":790,"y":120,"width":320,"height":430,"rotationDeg":0,"borderRadius":20,"objectFit":"cover"},
      {"slotIndex":3,"x":90,"y":590,"width":320,"height":430,"rotationDeg":0,"borderRadius":20,"objectFit":"cover"},
      {"slotIndex":4,"x":440,"y":590,"width":320,"height":430,"rotationDeg":0,"borderRadius":20,"objectFit":"cover"},
      {"slotIndex":5,"x":790,"y":590,"width":320,"height":430,"rotationDeg":0,"borderRadius":20,"objectFit":"cover"}
    ]'::jsonb,
    true
  ),
  (
    'layout-8-portrait',
    '8 Photo Portrait',
    1200,
    1800,
    8,
    '[
      {"slotIndex":0,"x":100,"y":100,"width":230,"height":330,"rotationDeg":0,"borderRadius":18,"objectFit":"cover"},
      {"slotIndex":1,"x":360,"y":100,"width":230,"height":330,"rotationDeg":0,"borderRadius":18,"objectFit":"cover"},
      {"slotIndex":2,"x":620,"y":100,"width":230,"height":330,"rotationDeg":0,"borderRadius":18,"objectFit":"cover"},
      {"slotIndex":3,"x":880,"y":100,"width":230,"height":330,"rotationDeg":0,"borderRadius":18,"objectFit":"cover"},
      {"slotIndex":4,"x":100,"y":470,"width":230,"height":330,"rotationDeg":0,"borderRadius":18,"objectFit":"cover"},
      {"slotIndex":5,"x":360,"y":470,"width":230,"height":330,"rotationDeg":0,"borderRadius":18,"objectFit":"cover"},
      {"slotIndex":6,"x":620,"y":470,"width":230,"height":330,"rotationDeg":0,"borderRadius":18,"objectFit":"cover"},
      {"slotIndex":7,"x":880,"y":470,"width":230,"height":330,"rotationDeg":0,"borderRadius":18,"objectFit":"cover"}
    ]'::jsonb,
    true
  )
on conflict (id) do update set
  name = excluded.name,
  canvas_width = excluded.canvas_width,
  canvas_height = excluded.canvas_height,
  slot_count = excluded.slot_count,
  slots = excluded.slots,
  is_active = excluded.is_active,
  updated_at = now();

insert into public.templates (
  id,
  layout_id,
  name,
  background_storage_path,
  background_public_url,
  canvas_width,
  canvas_height,
  is_active
)
values
  (
    'template-default-4',
    'layout-4-portrait',
    'Default 4 Photo Template',
    null,
    null,
    1200,
    1800,
    true
  ),
  (
    'template-default-6',
    'layout-6-portrait',
    'Default 6 Photo Template',
    null,
    null,
    1200,
    1800,
    true
  ),
  (
    'template-default-8',
    'layout-8-portrait',
    'Default 8 Photo Template',
    null,
    null,
    1200,
    1800,
    true
  )
on conflict (id) do update set
  layout_id = excluded.layout_id,
  name = excluded.name,
  background_storage_path = excluded.background_storage_path,
  background_public_url = excluded.background_public_url,
  canvas_width = excluded.canvas_width,
  canvas_height = excluded.canvas_height,
  is_active = excluded.is_active,
  updated_at = now();
SQL

write_file "docs/supabase-phase-5c-security-storage-seed.md" <<'MD'
# Corra Booth Supabase Phase 5C

Phase 5C creates RLS, storage buckets, storage policies, and default layout seed data.

## Migrations

- 014_enable_rls.sql
- 015_create_rls_policies.sql
- 016_create_storage_buckets.sql
- 017_create_storage_policies.sql
- 018_seed_default_layouts.sql

## Buckets

- raw-photos: private
- final-frames: private
- gifs: private
- templates: public
- qris: private

## Download Flow

QR Code -> Netlify Download Page -> Supabase Edge Function -> Signed URL.

## Admin Bootstrap

After creating a Supabase Auth user, insert the first owner manually with service-role privileges.
MD

echo ""
echo "Verifying generated SQL files..."

SQL_COUNT="$(find infra/supabase/migrations -maxdepth 1 -type f -name "*.sql" | wc -l | tr -d ' ')"

echo "SQL migration count: $SQL_COUNT"

if [ "$SQL_COUNT" -lt 18 ]; then
  fail "Expected at least 18 SQL migration files after Phase 5C."
fi

for file in \
  "infra/supabase/migrations/014_enable_rls.sql" \
  "infra/supabase/migrations/015_create_rls_policies.sql" \
  "infra/supabase/migrations/016_create_storage_buckets.sql" \
  "infra/supabase/migrations/017_create_storage_policies.sql" \
  "infra/supabase/migrations/018_seed_default_layouts.sql"
do
  [ -f "$file" ] || fail "Missing file: $file"
done

ls -1 infra/supabase/migrations/*.sql | sort

echo ""
echo "========================================"
echo " Phase 5C completed."
echo "========================================"
echo ""
echo "Next:"
echo "  git add ."
echo "  git commit -m \"feat: add supabase security storage and seed migrations\""
echo ""
