-- Corra Booth
-- 017_create_storage_policies.sql

drop policy if exists storage_templates_public_read on storage.objects;
create policy storage_templates_public_read
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'templates');

drop policy if exists storage_staff_read_qris on storage.objects;
create policy storage_staff_read_qris
on storage.objects
for select
to authenticated
using (
  bucket_id = 'qris'
  and public.is_corra_staff()
);

drop policy if exists storage_admin_manage_template_qris on storage.objects;
create policy storage_admin_manage_template_qris
on storage.objects
for all
to authenticated
using (
  bucket_id in ('templates', 'qris')
  and public.is_corra_admin()
)
with check (
  bucket_id in ('templates', 'qris')
  and public.is_corra_admin()
);

drop policy if exists storage_staff_read_photo_assets on storage.objects;
create policy storage_staff_read_photo_assets
on storage.objects
for select
to authenticated
using (
  bucket_id in ('raw-photos', 'final-frames', 'gifs')
  and public.is_corra_staff()
);

drop policy if exists storage_admin_manage_photo_assets on storage.objects;
create policy storage_admin_manage_photo_assets
on storage.objects
for all
to authenticated
using (
  bucket_id in ('raw-photos', 'final-frames', 'gifs')
  and public.is_corra_admin()
)
with check (
  bucket_id in ('raw-photos', 'final-frames', 'gifs')
  and public.is_corra_admin()
);
