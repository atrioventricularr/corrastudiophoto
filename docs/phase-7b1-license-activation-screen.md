# Phase 7B1 - License Activation Screen

This phase adds the visible activation gate for the booth UI.

## Behavior

- Browser preview mode is allowed for development.
- Electron desktop mode requires a valid license.
- App checks local license cache on boot.
- If cache is valid, app opens Welcome.
- If cache is missing or invalid, app opens License Activation.
- Successful activation calls the Electron preload bridge and stores cache through Electron main.

## Files

- apps/booth-ui/src/components/LicenseActivationScreen.tsx
- apps/booth-ui/src/App.tsx
- apps/booth-ui/src/types.ts

## Next

Phase 7B2 or 7C should add white-label brand/theme/background config foundation.
