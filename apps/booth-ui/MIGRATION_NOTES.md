# Corra Booth UI Migration Notes

Phase 1 imported the prototype UI as-is into `apps/booth-ui`.

Current imported structure:

- `src/App.tsx`
- `src/main.tsx`
- `src/index.css`
- `src/constants.ts`
- `src/types.ts`
- `src/utils/audio.ts`
- `src/components/*`

Important:

This phase intentionally does not refactor components into `src/screens/*` yet.

Reason:

The first goal is to make the uploaded UI run inside the monorepo without breaking imports.

Next phase should split:

- `src/components/WelcomeScreen.tsx` → `src/screens/welcome/WelcomeScreen.tsx`
- `src/components/PaymentScreen.tsx` → `src/screens/payment/PaymentScreen.tsx`
- `src/components/LayoutSelectionScreen.tsx` → `src/screens/layout-selection/LayoutSelectionScreen.tsx`
- `src/components/TemplateSelectionScreen.tsx` → `src/screens/template-selection/TemplateSelectionScreen.tsx`
- `src/components/CameraCaptureScreen.tsx` → `src/screens/camera-capture/CameraCaptureScreen.tsx`
- `src/components/ProcessingScreen.tsx` → `src/screens/processing/ProcessingScreen.tsx`
- `src/components/ResultScreen.tsx` → `src/screens/result/ResultScreen.tsx`
- `src/components/AdminPanel.tsx` → `src/screens/admin/AdminPanel.tsx`

Do not place Electron, Windows SDK, printer logic, Mayar secrets, or Supabase service-role keys inside this UI app.

