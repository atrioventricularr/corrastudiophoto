@echo off
set CORRA_DEV=0
set CORRA_KIOSK=1
set CORRA_DEVTOOLS=0
where electron >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  electron .
) else (
  echo Electron not found in PATH. Run pnpm install or use packaged installer.
  pause
)
