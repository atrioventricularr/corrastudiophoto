# Phase 6B - Verify License Edge Function

This phase adds the `verify-license` Supabase Edge Function.

Input:

{
  "licenseCode": "CORRA-XXXXXXX",
  "deviceFingerprint": "DEVICE-FINGERPRINT",
  "deviceName": "Booth PC 1",
  "platform": "WINDOWS_ELECTRON"
}

Main behavior:

- Checks license existence
- Checks license status
- Checks active date window
- Registers new booth device if device limit allows
- Updates `last_seen_at` for existing device
- Writes activation logs to `license_activations`

Deploy later with:

pnpm exec supabase functions deploy verify-license

Do not expose service-role key to frontend, Electron renderer, or GitHub.
