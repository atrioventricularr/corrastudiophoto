# Phase 10 — Production Hardening / Installer Prep

Status: scaffold complete after TypeScript and production audit pass.

Included:
- 10A production security checklist storage/types
- 10B production security UI panel
- 10C production audit script
- 10D production bundle builder/checker
- 10E Windows dev/production launch helpers
- 10F root package script helpers
- 10G docs/checker

Important production notes:
- Do not place `SUPABASE_SERVICE_ROLE_KEY` or `MAYAR_API_KEY` in frontend `.env`.
- Supabase service role and Mayar API key must only be set as Supabase Edge Function secrets.
- `--no-verify-jwt` is acceptable for early dev, but production should add booth/device auth.
- Windows installer signing is not included here; that should be Phase 11 or external release ops.
- Test kiosk, printer, and camera on the actual Windows booth PC.

Commands:
```bash
pnpm --filter @corra/booth-ui exec tsc --noEmit --pretty false
bash scripts/audit-corra-production.sh
bash scripts/build-corra-production-bundle.sh
bash scripts/check-corra-production-bundle.sh
```
