create table if not exists public.booth_cloud_asset_uploads (
  id uuid primary key default gen_random_uuid(),
  local_asset_id text,
  session_id text not null,
  asset_kind text not null check (asset_kind in ('raw_capture', 'final_output')),
  bucket_name text not null,
  storage_path text not null,
  filename text not null,
  mime_type text not null default 'image/png',
  size_bytes bigint not null default 0,
  signed_url text,
  signed_url_expires_at timestamptz,
  slot_id text,
  output_id text,
  template_id text,
  template_name text,
  layout_id text,
  layout_name text,
  render_mode text,
  width_px integer,
  height_px integer,
  source text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists booth_cloud_asset_uploads_session_id_idx
  on public.booth_cloud_asset_uploads(session_id);

create index if not exists booth_cloud_asset_uploads_asset_kind_idx
  on public.booth_cloud_asset_uploads(asset_kind);

create index if not exists booth_cloud_asset_uploads_created_at_idx
  on public.booth_cloud_asset_uploads(created_at desc);

alter table public.booth_cloud_asset_uploads enable row level security;

drop policy if exists "Service role can manage booth cloud asset uploads"
  on public.booth_cloud_asset_uploads;

create policy "Service role can manage booth cloud asset uploads"
  on public.booth_cloud_asset_uploads
  for all
  using (auth.role() = 'service_role')
  with check (auth.role() = 'service_role');
