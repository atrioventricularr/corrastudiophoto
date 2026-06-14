#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - Phase 7A2 Booth UI Desktop API"
echo "========================================"

fail() {
  echo ""
  echo "ERROR: $1"
  echo ""
  exit 1
}

write_file() {
  local file_path="$1"
  mkdir -p "$(dirname "$file_path")"
  cat > "$file_path"
  echo "WRITE file: $file_path"
}

echo ""
echo "Checking repository..."

[ -f "package.json" ] || fail "Root package.json not found. Run this from repo root."
[ -d "apps/booth-ui/src" ] || fail "apps/booth-ui/src not found."
[ -f "apps/desktop-electron/electron/preload/preload.cjs" ] || fail "Electron preload not found. Run Phase 7A1 first."

echo "Repository OK."

echo ""
echo "Writing booth-ui desktop API helper..."

write_file "apps/booth-ui/src/lib/desktop-api.ts" <<'TS'
export type CorraDesktopDeviceInfo = {
  fingerprint: string;
  deviceName: string;
  platform: "WINDOWS_ELECTRON";
  osPlatform: string;
  osRelease: string;
  arch: string;
};

export type CorraVerifyLicenseInput = {
  licenseCode: string;
  deviceName?: string;
};

export type CorraVerifyLicenseResult = {
  valid: boolean;
  reason?: string;
  source?: string;
  checkedAt?: string;
  verifyUrl?: string;
  license?: {
    id: string;
    licenseCode: string;
    ownerEmail: string;
    ownerName: string | null;
    billingCycle: string;
    activeFrom: string | null;
    activeUntil: string | null;
    maxDevices: number;
  };
  device?: {
    id: string;
    alreadyActivated: boolean;
  };
  deviceInfo?: CorraDesktopDeviceInfo;
  mayar?: Record<string, unknown>;
  detail?: string;
  response?: unknown;
  raw?: string;
};

export function isCorraDesktop(): boolean {
  return typeof window !== "undefined" && Boolean(window.corraDesktop);
}

export async function getDesktopDeviceInfo(): Promise<CorraDesktopDeviceInfo | null> {
  if (!window.corraDesktop) {
    return null;
  }

  return window.corraDesktop.device.getInfo();
}

export async function verifyDesktopLicense(
  input: CorraVerifyLicenseInput,
): Promise<CorraVerifyLicenseResult> {
  if (!window.corraDesktop) {
    return {
      valid: false,
      reason: "Corra Desktop bridge is not available. Run inside Electron.",
    };
  }

  return window.corraDesktop.license.verify(input);
}

export async function readDesktopLicenseCache(): Promise<CorraVerifyLicenseResult | null> {
  if (!window.corraDesktop) {
    return null;
  }

  return window.corraDesktop.license.readCache();
}

export async function clearDesktopLicenseCache(): Promise<{ ok: boolean }> {
  if (!window.corraDesktop) {
    return {
      ok: false,
    };
  }

  return window.corraDesktop.license.clearCache();
}
TS

echo ""
echo "Writing global window type declaration..."

write_file "apps/booth-ui/src/types/corra-desktop.d.ts" <<'TS'
export {};

declare global {
  type CorraDesktopDeviceInfo = {
    fingerprint: string;
    deviceName: string;
    platform: "WINDOWS_ELECTRON";
    osPlatform: string;
    osRelease: string;
    arch: string;
  };

  type CorraVerifyLicenseResult = {
    valid: boolean;
    reason?: string;
    source?: string;
    checkedAt?: string;
    verifyUrl?: string;
    license?: {
      id: string;
      licenseCode: string;
      ownerEmail: string;
      ownerName: string | null;
      billingCycle: string;
      activeFrom: string | null;
      activeUntil: string | null;
      maxDevices: number;
    };
    device?: {
      id: string;
      alreadyActivated: boolean;
    };
    deviceInfo?: CorraDesktopDeviceInfo;
    mayar?: Record<string, unknown>;
    detail?: string;
    response?: unknown;
    raw?: string;
  };

  interface Window {
    corraDesktop?: {
      device: {
        getInfo: () => Promise<CorraDesktopDeviceInfo>;
      };
      license: {
        verify: (input: {
          licenseCode: string;
          deviceName?: string;
        }) => Promise<CorraVerifyLicenseResult>;
        readCache: () => Promise<CorraVerifyLicenseResult | null>;
        clearCache: () => Promise<{ ok: boolean }>;
      };
    };
  }
}
TS

echo ""
echo "Writing docs..."

write_file "docs/phase-7a2-booth-ui-desktop-api.md" <<'MD'
# Phase 7A2 - Booth UI Desktop API

This phase adds a typed helper layer for React to communicate with Electron preload.

## Files

- apps/booth-ui/src/lib/desktop-api.ts
- apps/booth-ui/src/types/corra-desktop.d.ts

## Available Helpers

- isCorraDesktop()
- getDesktopDeviceInfo()
- verifyDesktopLicense()
- readDesktopLicenseCache()
- clearDesktopLicenseCache()

## Next

Phase 7B should add the visible License Activation screen.
MD

echo ""
echo "Verifying files..."

[ -f "apps/booth-ui/src/lib/desktop-api.ts" ] || fail "Missing desktop-api.ts."
[ -f "apps/booth-ui/src/types/corra-desktop.d.ts" ] || fail "Missing corra-desktop.d.ts."
[ -f "docs/phase-7a2-booth-ui-desktop-api.md" ] || fail "Missing docs."

echo ""
echo "========================================"
echo " Phase 7A2 completed."
echo "========================================"
echo ""
echo "Next:"
echo "  pnpm --filter @corra/booth-ui typecheck"
echo "  git add ."
echo "  git commit -m \"feat: add booth ui desktop api bridge\""
echo ""
