# Phase 6B - Verify License via Mayar

This phase replaces the previous `verify-license` function.

## Source of Truth

Mayar is the source of truth for license status.

Supabase stores:

- cached license data
- booth device binding
- activation logs
- app/business data

## Required Secrets

- MAYAR_API_KEY
- MAYAR_PRODUCT_ID
- SUPABASE_SERVICE_ROLE_KEY if not available by default

## Flow

Electron app sends license code and device fingerprint.

The Edge Function:

1. Calls Mayar Software License Verify API.
2. Checks `isLicenseActive`.
3. Syncs license data to Supabase.
4. Checks local device limit.
5. Creates or updates booth device.
6. Returns valid/invalid response.

## Endpoint

https://PROJECT_REF.supabase.co/functions/v1/verify-license

## Deploy

pnpm exec supabase functions deploy verify-license
