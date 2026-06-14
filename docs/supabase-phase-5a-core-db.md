# Corra Booth Supabase Phase 5A

Phase 5A creates the core database foundation.

## Created Migrations

- `001_enable_extensions.sql`
- `002_create_enums.sql`
- `003_create_updated_at_function.sql`
- `004_create_licenses.sql`
- `005_create_booth_devices.sql`
- `006_create_license_activations.sql`
- `007_create_photo_sessions.sql`
- `008_create_photo_assets.sql`
- `009_create_transactions.sql`

## Not Included Yet

These are intentionally delayed to Phase 5B and 5C:

- layouts
- templates
- vouchers
- admin_users
- business_settings
- RLS policies
- storage buckets
- seed data

## Important

Do not push to Supabase before all Phase 5 migration files are complete, unless you intentionally want to test the schema incrementally.
