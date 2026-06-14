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
