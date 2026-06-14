# Phase 6A - License Foundation

Phase 6A adds:

- `mayar_webhook_events` table
- shared CORS helper
- shared env helper
- shared Supabase admin client
- shared object/path helper

## Why `mayar_webhook_events` exists

Mayar webhooks can be retried. This table makes webhook processing idempotent and auditable.

## Next

- Phase 6B: `verify-license` Edge Function
- Phase 6C: `mayar-webhook` Edge Function
- Phase 6D: deploy functions and set secrets
