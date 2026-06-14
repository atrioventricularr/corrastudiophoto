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
