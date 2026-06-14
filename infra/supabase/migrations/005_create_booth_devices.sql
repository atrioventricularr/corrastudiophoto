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
