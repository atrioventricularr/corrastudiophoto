# License Flow

Planned flow:

Mayar payment success → Mayar webhook → Supabase Edge Function → licenses table updated → Electron app verifies license status.

Electron must never store Mayar secret keys or Supabase service-role keys.

