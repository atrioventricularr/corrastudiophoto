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
