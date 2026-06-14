-- Corra Booth
-- 014_enable_rls.sql

alter table public.licenses enable row level security;
alter table public.booth_devices enable row level security;
alter table public.license_activations enable row level security;
alter table public.photo_sessions enable row level security;
alter table public.photo_assets enable row level security;
alter table public.transactions enable row level security;
alter table public.layouts enable row level security;
alter table public.templates enable row level security;
alter table public.vouchers enable row level security;
alter table public.admin_users enable row level security;
alter table public.business_settings enable row level security;
