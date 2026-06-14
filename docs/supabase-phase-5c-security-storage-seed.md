# Corra Booth Supabase Phase 5C

Phase 5C creates RLS, storage buckets, storage policies, and default layout seed data.

## Migrations

- 014_enable_rls.sql
- 015_create_rls_policies.sql
- 016_create_storage_buckets.sql
- 017_create_storage_policies.sql
- 018_seed_default_layouts.sql

## Buckets

- raw-photos: private
- final-frames: private
- gifs: private
- templates: public
- qris: private

## Download Flow

QR Code -> Netlify Download Page -> Supabase Edge Function -> Signed URL.

## Admin Bootstrap

After creating a Supabase Auth user, insert the first owner manually with service-role privileges.
