# Phase 9D — Real Payment Integration

Scope:
- Unified payment intent table
- Mayar checkout create function
- Mayar status check function
- Mayar webhook receiver
- Frontend payment runtime storage
- Frontend runtime payment test panel
- Provider diagnostics panel

Deploy:
```bash
pnpm dlx supabase db push
pnpm dlx supabase functions deploy create-mayar-checkout --no-verify-jwt
pnpm dlx supabase functions deploy check-mayar-transaction-status --no-verify-jwt
pnpm dlx supabase functions deploy mayar-payment-webhook --no-verify-jwt
```

Required Edge Function secret:
```bash
pnpm dlx supabase secrets set MAYAR_API_KEY=your_mayar_api_key
```

Test:
```txt
?mode=booth&dev=1
```

Known limitation:
- DOKU bridge is left as a placeholder because 8D already has DOKU functions and needs project-specific type reconciliation.
- For production, do not leave create/check/delete payment functions fully public without a booth/device token layer.
