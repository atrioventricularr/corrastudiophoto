# Phase 9F — Printer / Kiosk Hardware Testing Checklist

Status: code scaffold complete after typecheck passes.

Completed:
- 9F1 Electron hardware diagnostics IPC
- 9F2 Electron preload hardware bridge
- 9F3 Frontend hardware API/storage
- 9F4 Runtime diagnostics panel
- 9F5 Printer discovery and print test panel
- 9F6 Camera discovery and preview test panel
- 9F7 Kiosk fullscreen/kiosk controls
- 9F8 Production readiness panel
- 9F9 Booth dev integration
- 9F10 Export wiring
- 9F11 Electron CJS bridge patch
- 9F12 Docs/checker

Important:
- Browser Vite cannot access `window.corraHardware`.
- Hardware bridge only works inside Electron.
- Print test uses Electron `webContents.print`.
- Silent print may depend on OS/printer driver support.

Test:
```txt
?mode=booth&dev=1
```

Recommended run order:
1. Hardware Diagnostics → Run
2. Printer Hardware Test → Refresh Printers
3. Printer Hardware Test → Print Test
4. Camera Hardware Test → Refresh Cameras
5. Camera Hardware Test → Start Preview
6. Kiosk Runtime Test → Fullscreen On
7. Kiosk Runtime Test → Kiosk On
8. Production Readiness → Refresh
