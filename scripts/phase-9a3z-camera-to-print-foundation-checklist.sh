#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9A3Z - Camera to Print Checklist"
echo "========================================"

mkdir -p docs

cat > docs/phase-9a3-camera-to-print-foundation-checklist.md <<'MD'
# Phase 9A3 — Camera-to-Print Foundation Checklist

Status: **Foundation complete**

This phase connects the admin camera workflow from live preview to captured frames, final render, print candidate selection, local print queue, and Electron print bridge foundation.

---

## Completed

### Camera Preview Guide

- [x] Camera guide overlay component
- [x] Grid overlay
- [x] Layout slot guide overlay
- [x] Active capture slot highlight
- [x] Mirror preview toggle
- [x] Mirror final output option

Files:

- `apps/booth-ui/src/camera/CameraGuideOverlay.tsx`
- `apps/booth-ui/src/camera/CameraLivePreview.tsx`
- `apps/booth-ui/src/camera/CameraCaptureGuideProvider.tsx`
- `apps/booth-ui/src/camera/CameraCaptureGuidePanel.tsx`

---

## Capture Flow

- [x] Capture slot order based on layout `captureOrder`
- [x] Previous / next / reset pose navigation
- [x] Countdown capture foundation
- [x] Capture image from video frame
- [x] Save captured frame per slot
- [x] Captured frames panel
- [x] Capture completion status
- [x] Auto-advance after capture option

Files:

- `apps/booth-ui/src/camera/capture-guide.ts`
- `apps/booth-ui/src/camera/capture-frame.ts`
- `apps/booth-ui/src/camera/capture-completion.ts`
- `apps/booth-ui/src/camera/CameraCountdownPanel.tsx`
- `apps/booth-ui/src/camera/CapturedFramesProvider.tsx`
- `apps/booth-ui/src/camera/CapturedFramesPanel.tsx`
- `apps/booth-ui/src/camera/CameraCaptureCompletionPanel.tsx`

---

## Render Flow

- [x] Render captured frames into active template
- [x] Raw template render mode
- [x] Print-ready render mode
- [x] Auto-render when all poses complete
- [x] Save latest render output to local session
- [x] Output history
- [x] Select output from history
- [x] Mark selected output as print candidate

Files:

- `apps/booth-ui/src/camera/CameraCapturedRenderPanel.tsx`
- `apps/booth-ui/src/camera/CameraRenderOutputProvider.tsx`
- `apps/booth-ui/src/camera/CameraRenderOutputPanel.tsx`
- `apps/booth-ui/src/render/final-renderer.ts`
- `apps/booth-ui/src/render/print-ready-renderer.ts`

---

## Print Queue Flow

- [x] Create local print job from print candidate
- [x] Local print queue provider
- [x] Queue history
- [x] Job statuses:
  - queued
  - printing
  - completed
  - failed
  - cancelled
- [x] Print job result details
- [x] Print queue completion summary
- [x] Auto-print new jobs option
- [x] Silent print / print dialog toggle

Files:

- `apps/booth-ui/src/camera/CameraPrintQueueProvider.tsx`
- `apps/booth-ui/src/camera/CameraPrintQueuePanel.tsx`
- `apps/booth-ui/src/camera/CameraPrintQueueSummaryPanel.tsx`

---

## Electron Print Bridge Foundation

- [x] UI print bridge helper
- [x] Bridge availability detection
- [x] Electron preload print bridge exposure
- [x] Electron main IPC print handler
- [x] Printer list bridge
- [x] Selected printer support
- [x] Silent print flag support

Files:

- `apps/booth-ui/src/camera/print-bridge.ts`
- Electron preload file
- Electron main file

Notes:

- Browser/Codespaces will show `Bridge missing`.
- Printer list and real printing only work inside Electron local runtime.
- Silent print depends on printer driver and OS permissions.

---

## End-to-End Session UX

- [x] Camera-to-print checklist panel
- [x] Local customer session reset
- [x] Reset clears:
  - captured frames
  - render outputs
  - selected print candidate
  - print queue
  - active pose index

Files:

- `apps/booth-ui/src/camera/CameraToPrintFlowChecklistPanel.tsx`
- `apps/booth-ui/src/camera/CameraCustomerSessionResetPanel.tsx`

---

## Current Admin Flow

Admin → Hardware → Camera Setup:

1. Select camera device
2. Preview camera
3. Use grid / slot guide overlay
4. Navigate pose slot
5. Start countdown
6. Capture frame
7. Repeat until all required poses complete
8. Render captured template
9. Select output
10. Mark as print candidate
11. Create print job
12. Print via bridge / mark completed
13. Reset customer session

---

## Known Limitations

- Camera capture is still inside Admin Hardware page, not yet customer-facing booth mode.
- Captured frames and outputs are local memory only.
- No disk persistence yet for captured raw/final photos.
- No Supabase upload yet for raw/final session outputs.
- Electron print handler is foundation-level and needs real Windows printer testing.
- Print sizing depends on OS/printer driver behavior and may need calibration.
- Session lifecycle provider is not fully connected to every camera/render/print event yet.
- Payment-to-camera gate is not yet customer-facing.

---

## Next Recommended Phase

### Phase 9B — Customer-Facing Booth Flow

Goal:

Move the working admin camera-to-print foundation into a real customer booth flow.

Recommended steps:

1. Booth session start screen
2. Payment confirmed gate
3. Layout/template preview for customer
4. Customer camera screen
5. Countdown capture full-screen mode
6. Retake / accept photo flow
7. Auto-render final output
8. Delivery / QR / print step
9. Reset to welcome screen

---

## Definition of Done for Phase 9A3

- [x] Admin can preview camera with layout guide overlay
- [x] Admin can capture photos per layout slot
- [x] Captured photos can render into a template
- [x] Render output can be selected
- [x] Selected output can become print candidate
- [x] Print candidate can create local print job
- [x] Print job can call Electron print bridge
- [x] Flow checklist shows readiness
- [x] Session can be reset locally

Phase 9A3 is ready to close.
MD

echo ""
echo "Created:"
ls -lh docs/phase-9a3-camera-to-print-foundation-checklist.md

echo ""
echo "9A3Z done."
