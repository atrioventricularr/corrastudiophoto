# Phase 6C - Mayar Webhook Edge Function

This phase adds the `mayar-webhook` Supabase Edge Function.

Main behavior:

- Receives Mayar webhook payload
- Stores raw payload in `mayar_webhook_events`
- Ignores non-paid statuses
- Creates or updates an ACTIVE license for paid/success statuses
- Uses `event_id`/transaction data for idempotency
- Supports optional webhook secret via header or query parameter

Webhook endpoint after deploy:

https://PROJECT_REF.supabase.co/functions/v1/mayar-webhook

Optional development secret format:

https://PROJECT_REF.supabase.co/functions/v1/mayar-webhook?secret=YOUR_SECRET

Supported custom header:

x-corra-webhook-secret: YOUR_SECRET

Important:

The current payload mapping is defensive. After receiving a real Mayar webhook payload, adjust field paths if Mayar uses different names.
