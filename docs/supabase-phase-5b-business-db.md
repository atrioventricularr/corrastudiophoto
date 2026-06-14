# Corra Booth Supabase Phase 5B

Phase 5B creates business-side database tables.

## Created Migrations

- `010_create_business_enums.sql`
- `011_create_layouts_templates.sql`
- `012_create_vouchers_admin_business_settings.sql`
- `013_create_admin_helper_functions.sql`

## Created Tables

- `layouts`
- `templates`
- `vouchers`
- `admin_users`
- `business_settings`

## Created Helper Functions

- `public.is_corra_admin()`
- `public.is_corra_staff()`

## Not Included Yet

These are intentionally delayed to Phase 5C:

- RLS policies
- Storage buckets
- Storage policies
- Default layout seed data

## Important

The first admin still needs to be bootstrapped manually later after Supabase Auth user creation.
