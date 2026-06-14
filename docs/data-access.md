# Corra Booth Data Access

Phase 4 creates the data-access skeleton.

## Responsibilities

`packages/data-access` handles:

- Supabase client creation
- License repository
- Photo session repository
- Photo asset repository
- Supabase Storage repository
- Transaction log repository
- Local settings repository
- Offline queue skeleton

## Security Boundary

Do not put these inside the booth UI:

- Mayar API key
- Mayar webhook secret
- Supabase service-role key
- Any backend-only secret

The booth UI may use:

- Supabase URL
- Supabase anon key

The service-role key is only for:

- Supabase Edge Functions
- trusted server runtime
- backend scripts

## Storage Note

The generic `SupabaseStorageRepository` can upload browser-readable URLs:

- data URL
- blob URL
- http URL
- https URL

It intentionally cannot read raw filesystem paths.

For Electron production, create a dedicated Electron storage adapter that reads files from disk in the main process, then uploads the binary safely.

## Planned Repositories

Current skeleton:

- `SupabaseLicenseRepository`
- `SupabaseStorageRepository`
- `SupabasePhotoRepository`
- `SupabaseTransactionLogRepository`
- `MemoryLocalSettingsRepository`
- `BrowserLocalStorageSettingsRepository`
- `MemoryOfflineQueueRepository`

## Next Phase

Phase 5 should create Supabase SQL migrations:

- licenses
- booth_devices
- transactions
- photo_sessions
- photo_assets
- templates
- layouts
- vouchers
- admin_users
