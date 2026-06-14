-- Corra Booth
-- 011_create_layouts_templates.sql

create table if not exists public.layouts (
  id text primary key,

  name text not null,

  canvas_width integer not null,
  canvas_height integer not null,

  slot_count integer not null,
  slots jsonb not null default '[]'::jsonb,

  is_active boolean not null default true,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint layouts_id_not_empty check (length(trim(id)) > 0),
  constraint layouts_name_not_empty check (length(trim(name)) > 0),
  constraint layouts_canvas_width_positive check (canvas_width > 0),
  constraint layouts_canvas_height_positive check (canvas_height > 0),
  constraint layouts_slot_count_valid check (slot_count between 2 and 8),
  constraint layouts_slots_is_array check (jsonb_typeof(slots) = 'array')
);

create index if not exists idx_layouts_is_active
  on public.layouts (is_active);

create index if not exists idx_layouts_slot_count
  on public.layouts (slot_count);

drop trigger if exists trg_layouts_set_updated_at on public.layouts;

create trigger trg_layouts_set_updated_at
before update on public.layouts
for each row
execute function public.set_updated_at();

create table if not exists public.templates (
  id text primary key,

  layout_id text not null references public.layouts(id) on delete cascade,

  name text not null,

  background_storage_path text,
  background_public_url text,

  canvas_width integer not null,
  canvas_height integer not null,

  is_active boolean not null default true,

  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint templates_id_not_empty check (length(trim(id)) > 0),
  constraint templates_name_not_empty check (length(trim(name)) > 0),
  constraint templates_canvas_width_positive check (canvas_width > 0),
  constraint templates_canvas_height_positive check (canvas_height > 0)
);

create index if not exists idx_templates_layout_id
  on public.templates (layout_id);

create index if not exists idx_templates_is_active
  on public.templates (is_active);

drop trigger if exists trg_templates_set_updated_at on public.templates;

create trigger trg_templates_set_updated_at
before update on public.templates
for each row
execute function public.set_updated_at();
