# Phase 11 — Windows Installer / Signing / Real Machine QA

Status: scaffold complete after TypeScript and installer readiness checks pass.

Included:
- 11A installer readiness types/storage
- 11B installer readiness UI panel
- 11C electron-builder config
- 11D Windows installer build/check scripts
- 11E PowerShell signing script
- 11F Windows smoke-test checklist
- 11G package scripts and docs

Commands:
```bash
pnpm --filter @corra/booth-ui exec tsc --noEmit --pretty false
bash scripts/check-windows-installer-readiness.sh
bash scripts/build-windows-installer.sh
bash scripts/check-windows-installer-output.sh
```

Windows signing:
```powershell
$env:WINDOWS_PFX_PATH="C:\path\cert.pfx"
$env:WINDOWS_PFX_PASSWORD="password"
.\scripts\sign-windows-artifacts.ps1
```

Or with cert thumbprint:
```powershell
$env:WINDOWS_CERT_THUMBPRINT="..."
.\scripts\sign-windows-artifacts.ps1
```

Real machine QA:
```powershell
.\scripts\run-windows-smoke-test-checklist.ps1
```

Notes:
- Signing requires Windows SDK `signtool.exe`.
- Real printer/camera/kiosk must be tested on actual booth PC.
- Unsigned installer may trigger Windows SmartScreen.
