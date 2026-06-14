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
