# Phase 9G — Packaging / Release Candidate Checklist

Status: code scaffold complete after typecheck passes.

Completed:
- 9G1 Release readiness types/storage
- 9G2 Release diagnostics helper
- 9G3 Release diagnostics/readiness UI panels
- 9G4 Release manifest panel
- 9G5 Booth dev integration
- 9G6 Export wiring
- 9G7 Build/package scripts
- 9G8 Root package script helpers
- 9G9 Docs/checker
- 9G10 Phase 9 close status

Commands:
```bash
pnpm --filter @corra/booth-ui exec tsc --noEmit --pretty false
bash scripts/build-booth-ui-release.sh
bash scripts/make-corra-release-candidate.sh
bash scripts/check-corra-release-candidate.sh
```

Manual QA:
1. Run inside Electron.
2. Activate license.
3. Test payment flow.
4. Test camera preview/capture.
5. Test final render.
6. Test disk save.
7. Test cloud upload/share link.
8. Test printer.
9. Test kiosk fullscreen/admin unlock.
10. Mark Release Candidate Readiness as passed.

Known limitation:
- This phase creates a release candidate bundle, not a signed Windows installer.
- Signed installer can be Phase 10 / production distribution hardening.
