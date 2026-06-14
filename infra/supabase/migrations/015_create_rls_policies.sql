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
