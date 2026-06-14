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
