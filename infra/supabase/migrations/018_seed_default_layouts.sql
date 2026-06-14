-- Corra Booth
-- 018_seed_default_layouts.sql

insert into public.layouts (
  id,
  name,
  canvas_width,
  canvas_height,
  slot_count,
  slots,
  is_active
)
values
  (
    'layout-4-portrait',
    '4 Photo Portrait',
    1200,
    1800,
    4,
    '[
      {"slotIndex":0,"x":120,"y":140,"width":460,"height":620,"rotationDeg":0,"borderRadius":24,"objectFit":"cover"},
      {"slotIndex":1,"x":620,"y":140,"width":460,"height":620,"rotationDeg":0,"borderRadius":24,"objectFit":"cover"},
      {"slotIndex":2,"x":120,"y":820,"width":460,"height":620,"rotationDeg":0,"borderRadius":24,"objectFit":"cover"},
      {"slotIndex":3,"x":620,"y":820,"width":460,"height":620,"rotationDeg":0,"borderRadius":24,"objectFit":"cover"}
    ]'::jsonb,
    true
  ),
  (
    'layout-6-portrait',
    '6 Photo Portrait',
    1200,
    1800,
    6,
    '[
      {"slotIndex":0,"x":90,"y":120,"width":320,"height":430,"rotationDeg":0,"borderRadius":20,"objectFit":"cover"},
      {"slotIndex":1,"x":440,"y":120,"width":320,"height":430,"rotationDeg":0,"borderRadius":20,"objectFit":"cover"},
      {"slotIndex":2,"x":790,"y":120,"width":320,"height":430,"rotationDeg":0,"borderRadius":20,"objectFit":"cover"},
      {"slotIndex":3,"x":90,"y":590,"width":320,"height":430,"rotationDeg":0,"borderRadius":20,"objectFit":"cover"},
      {"slotIndex":4,"x":440,"y":590,"width":320,"height":430,"rotationDeg":0,"borderRadius":20,"objectFit":"cover"},
      {"slotIndex":5,"x":790,"y":590,"width":320,"height":430,"rotationDeg":0,"borderRadius":20,"objectFit":"cover"}
    ]'::jsonb,
    true
  ),
  (
    'layout-8-portrait',
    '8 Photo Portrait',
    1200,
    1800,
    8,
    '[
      {"slotIndex":0,"x":100,"y":100,"width":230,"height":330,"rotationDeg":0,"borderRadius":18,"objectFit":"cover"},
      {"slotIndex":1,"x":360,"y":100,"width":230,"height":330,"rotationDeg":0,"borderRadius":18,"objectFit":"cover"},
      {"slotIndex":2,"x":620,"y":100,"width":230,"height":330,"rotationDeg":0,"borderRadius":18,"objectFit":"cover"},
      {"slotIndex":3,"x":880,"y":100,"width":230,"height":330,"rotationDeg":0,"borderRadius":18,"objectFit":"cover"},
      {"slotIndex":4,"x":100,"y":470,"width":230,"height":330,"rotationDeg":0,"borderRadius":18,"objectFit":"cover"},
      {"slotIndex":5,"x":360,"y":470,"width":230,"height":330,"rotationDeg":0,"borderRadius":18,"objectFit":"cover"},
      {"slotIndex":6,"x":620,"y":470,"width":230,"height":330,"rotationDeg":0,"borderRadius":18,"objectFit":"cover"},
      {"slotIndex":7,"x":880,"y":470,"width":230,"height":330,"rotationDeg":0,"borderRadius":18,"objectFit":"cover"}
    ]'::jsonb,
    true
  )
on conflict (id) do update set
  name = excluded.name,
  canvas_width = excluded.canvas_width,
  canvas_height = excluded.canvas_height,
  slot_count = excluded.slot_count,
  slots = excluded.slots,
  is_active = excluded.is_active,
  updated_at = now();

insert into public.templates (
  id,
  layout_id,
  name,
  background_storage_path,
  background_public_url,
  canvas_width,
  canvas_height,
  is_active
)
values
  (
    'template-default-4',
    'layout-4-portrait',
    'Default 4 Photo Template',
    null,
    null,
    1200,
    1800,
    true
  ),
  (
    'template-default-6',
    'layout-6-portrait',
    'Default 6 Photo Template',
    null,
    null,
    1200,
    1800,
    true
  ),
  (
    'template-default-8',
    'layout-8-portrait',
    'Default 8 Photo Template',
    null,
    null,
    1200,
    1800,
    true
  )
on conflict (id) do update set
  layout_id = excluded.layout_id,
  name = excluded.name,
  background_storage_path = excluded.background_storage_path,
  background_public_url = excluded.background_public_url,
  canvas_width = excluded.canvas_width,
  canvas_height = excluded.canvas_height,
  is_active = excluded.is_active,
  updated_at = now();
