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
