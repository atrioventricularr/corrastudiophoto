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
