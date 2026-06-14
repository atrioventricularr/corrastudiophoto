#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - Phase 7E1 Local Background Picker"
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

[ -f "apps/desktop-electron/electron/main/index.cjs" ] || fail "Electron main not found. Run 7A1 first."
[ -f "apps/desktop-electron/electron/preload/preload.cjs" ] || fail "Electron preload not found. Run 7A1 first."
[ -f "apps/booth-ui/src/components/admin/BrandAppearancePanel.tsx" ] || fail "BrandAppearancePanel not found. Run 7C1/7C2 first."
[ -f "apps/booth-ui/src/types/corra-desktop.d.ts" ] || fail "corra-desktop.d.ts not found. Run 7A2 first."

echo ""
echo "Patching Electron main process for local asset protocol and picker..."

python - <<'PY'
from pathlib import Path

path = Path("apps/desktop-electron/electron/main/index.cjs")
text = path.read_text()

text = text.replace(
    'const { app, BrowserWindow, ipcMain, shell } = require("electron");',
    'const { app, BrowserWindow, ipcMain, shell, dialog, protocol, net } = require("electron");'
)

if 'const { pathToFileURL } = require("node:url");' not in text:
    text = text.replace(
        'const path = require("node:path");',
        'const path = require("node:path");\nconst { pathToFileURL } = require("node:url");'
    )

if 'protocol.registerSchemesAsPrivileged' not in text:
    text = text.replace(
        'let mainWindow = null;',
        '''let mainWindow = null;

protocol.registerSchemesAsPrivileged([
  {
    scheme: "corra-asset",
    privileges: {
      standard: true,
      secure: true,
      supportFetchAPI: true,
      corsEnabled: true,
      stream: true,
    },
  },
]);'''
    )

asset_functions = r'''
function ensureDirectory(directoryPath) {
  fs.mkdirSync(directoryPath, {
    recursive: true,
  });
}

function getBrandAssetsRoot() {
  return path.join(app.getPath("userData"), "brand-assets");
}

function getAssetDirectory(kind) {
  return path.join(getBrandAssetsRoot(), kind);
}

function getAssetUrl(kind, filename) {
  return `corra-asset://${kind}/${encodeURIComponent(filename)}`;
}

function sanitizeAssetFilename(filename) {
  const ext = path.extname(filename).toLowerCase();
  const base = path
    .basename(filename, ext)
    .replace(/[^a-zA-Z0-9-_]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80) || "background";

  return `${Date.now()}-${base}${ext}`;
}

function getBackgroundTypeFromExtension(filePath) {
  const ext = path.extname(filePath).toLowerCase();

  if (ext === ".mp4") {
    return "video";
  }

  return "image";
}

function isSupportedBackgroundExtension(filePath) {
  const ext = path.extname(filePath).toLowerCase();

  return [".png", ".jpg", ".jpeg", ".webp", ".mp4"].includes(ext);
}

function registerAssetProtocol() {
  protocol.handle("corra-asset", async (request) => {
    try {
      const url = new URL(request.url);
      const kind = url.hostname;
      const filename = decodeURIComponent(url.pathname.replace(/^\/+/, ""));

      if (!kind || !filename) {
        return new Response("Not found", {
          status: 404,
        });
      }

      const assetRoot = path.normalize(getAssetDirectory(kind));
      const filePath = path.normalize(path.join(assetRoot, filename));

      if (!filePath.startsWith(assetRoot)) {
        return new Response("Forbidden", {
          status: 403,
        });
      }

      if (!fs.existsSync(filePath)) {
        return new Response("Not found", {
          status: 404,
        });
      }

      return net.fetch(pathToFileURL(filePath).toString());
    } catch (error) {
      return new Response(error instanceof Error ? error.message : "Asset protocol error", {
        status: 500,
      });
    }
  });
}

async function pickBackgroundAsset() {
  const result = await dialog.showOpenDialog(mainWindow, {
    title: "Choose Corra Booth Background",
    properties: ["openFile"],
    filters: [
      {
        name: "Background Assets",
        extensions: ["png", "jpg", "jpeg", "webp", "mp4"],
      },
      {
        name: "Images",
        extensions: ["png", "jpg", "jpeg", "webp"],
      },
      {
        name: "Videos",
        extensions: ["mp4"],
      },
    ],
  });

  if (result.canceled || !result.filePaths.length) {
    return {
      cancelled: true,
    };
  }

  const sourcePath = result.filePaths[0];

  if (!isSupportedBackgroundExtension(sourcePath)) {
    return {
      cancelled: true,
      error: "Unsupported background file. Use PNG, JPG, WebP, or MP4.",
    };
  }

  const kind = "backgrounds";
  const targetDirectory = getAssetDirectory(kind);
  ensureDirectory(targetDirectory);

  const filename = sanitizeAssetFilename(sourcePath);
  const targetPath = path.join(targetDirectory, filename);

  fs.copyFileSync(sourcePath, targetPath);

  return {
    cancelled: false,
    sourcePath,
    targetPath,
    filename,
    url: getAssetUrl(kind, filename),
    backgroundType: getBackgroundTypeFromExtension(sourcePath),
  };
}
'''

if 'function pickBackgroundAsset()' not in text:
    text = text.replace(
        'function registerIpcHandlers() {',
        asset_functions + '\nfunction registerIpcHandlers() {'
    )

if 'corra:asset-pick-background' not in text:
    text = text.replace(
        '''  ipcMain.handle("corra:license-clear-cache", async () => {
    return clearLicenseCache();
  });''',
        '''  ipcMain.handle("corra:license-clear-cache", async () => {
    return clearLicenseCache();
  });

  ipcMain.handle("corra:asset-pick-background", async () => {
    try {
      return await pickBackgroundAsset();
    } catch (error) {
      return {
        cancelled: true,
        error: error instanceof Error ? error.message : "Unknown asset picker error",
      };
    }
  });'''
    )

if 'registerAssetProtocol();' not in text:
    text = text.replace(
        '''app.whenReady().then(() => {
  registerIpcHandlers();''',
        '''app.whenReady().then(() => {
  registerAssetProtocol();
  registerIpcHandlers();'''
    )

path.write_text(text)
print("PATCH file: apps/desktop-electron/electron/main/index.cjs")
PY

echo ""
echo "Patching Electron preload bridge..."

python - <<'PY'
from pathlib import Path

path = Path("apps/desktop-electron/electron/preload/preload.cjs")
text = path.read_text()

if 'assets:' not in text:
    text = text.replace(
        '''  license: {
    verify: (input) => ipcRenderer.invoke("corra:license-verify", input),
    readCache: () => ipcRenderer.invoke("corra:license-read-cache"),
    clearCache: () => ipcRenderer.invoke("corra:license-clear-cache"),
  },''',
        '''  license: {
    verify: (input) => ipcRenderer.invoke("corra:license-verify", input),
    readCache: () => ipcRenderer.invoke("corra:license-read-cache"),
    clearCache: () => ipcRenderer.invoke("corra:license-clear-cache"),
  },
  assets: {
    pickBackground: () => ipcRenderer.invoke("corra:asset-pick-background"),
  },'''
    )

path.write_text(text)
print("PATCH file: apps/desktop-electron/electron/preload/preload.cjs")
PY

echo ""
echo "Writing booth-ui desktop asset helper..."

write_file "apps/booth-ui/src/lib/desktop-assets.ts" <<'TS'
export type CorraPickedBackgroundAsset = {
  cancelled: boolean;
  error?: string;
  sourcePath?: string;
  targetPath?: string;
  filename?: string;
  url?: string;
  backgroundType?: 'image' | 'video';
};

export function isDesktopBackgroundPickerAvailable(): boolean {
  return typeof window !== 'undefined' && Boolean(window.corraDesktop?.assets?.pickBackground);
}

export async function pickDesktopBackgroundAsset(): Promise<CorraPickedBackgroundAsset> {
  if (!window.corraDesktop?.assets?.pickBackground) {
    return {
      cancelled: true,
      error: 'Desktop background picker is only available inside Electron.',
    };
  }

  return window.corraDesktop.assets.pickBackground();
}
TS

echo ""
echo "Updating corra-desktop global types..."

write_file "apps/booth-ui/src/types/corra-desktop.d.ts" <<'TS'
export {};

declare global {
  type CorraDesktopDeviceInfo = {
    fingerprint: string;
    deviceName: string;
    platform: 'WINDOWS_ELECTRON';
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

  type CorraPickedBackgroundAsset = {
    cancelled: boolean;
    error?: string;
    sourcePath?: string;
    targetPath?: string;
    filename?: string;
    url?: string;
    backgroundType?: 'image' | 'video';
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
      assets: {
        pickBackground: () => Promise<CorraPickedBackgroundAsset>;
      };
    };
  }
}
TS

echo ""
echo "Replacing BrandAppearancePanel with local picker support..."

write_file "apps/booth-ui/src/components/admin/BrandAppearancePanel.tsx" <<'TSX'
import React, { useMemo, useState } from 'react';
import {
  CORRA_THEME_PRESETS,
  useBrandTheme,
  type CorraBackgroundFit,
  type CorraBackgroundType,
  type CorraThemeId,
} from '../../branding';
import {
  isDesktopBackgroundPickerAvailable,
  pickDesktopBackgroundAsset,
} from '../../lib/desktop-assets';

export default function BrandAppearancePanel() {
  const { brandConfig, updateBrandConfig, resetBrandConfig } = useBrandTheme();
  const [message, setMessage] = useState<string>('');
  const canPickLocalBackground = useMemo(
    () => isDesktopBackgroundPickerAvailable(),
    [],
  );

  const updateAppearance = (
    patch: Partial<typeof brandConfig.appearance>,
  ) => {
    updateBrandConfig({
      appearance: {
        ...brandConfig.appearance,
        ...patch,
      },
    });
  };

  const handlePickLocalBackground = async () => {
    setMessage('');

    const result = await pickDesktopBackgroundAsset();

    if (result.cancelled) {
      if (result.error) {
        setMessage(result.error);
      }

      return;
    }

    if (!result.url || !result.backgroundType) {
      setMessage('Background file selected, but no usable asset URL was returned.');
      return;
    }

    updateAppearance({
      backgroundType: result.backgroundType,
      backgroundValue: result.url,
      backgroundFit: 'cover',
      backgroundOpacity: 1,
    });

    setMessage(`Background selected: ${result.filename || result.url}`);
  };

  return (
    <div className="rounded-3xl border border-[var(--corra-border)] bg-[var(--corra-surface)] p-6 text-[var(--corra-text)]">
      <div className="mb-5">
        <h2 className="font-black text-2xl">Brand & Appearance</h2>
        <p className="text-sm text-[var(--corra-muted)]">
          White-label settings for customer brand, theme, and UI background.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">
            Business Name
          </span>
          <input
            value={brandConfig.businessName}
            onChange={(event) =>
              updateBrandConfig({ businessName: event.target.value })
            }
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          />
        </label>

        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">
            Tagline
          </span>
          <input
            value={brandConfig.tagline}
            onChange={(event) =>
              updateBrandConfig({ tagline: event.target.value })
            }
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          />
        </label>

        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">
            Theme
          </span>
          <select
            value={brandConfig.themeId}
            onChange={(event) =>
              updateBrandConfig({
                themeId: event.target.value as CorraThemeId,
              })
            }
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          >
            {Object.values(CORRA_THEME_PRESETS).map((theme) => (
              <option key={theme.id} value={theme.id}>
                {theme.name}
              </option>
            ))}
          </select>
        </label>

        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">
            Background Type
          </span>
          <select
            value={brandConfig.appearance.backgroundType}
            onChange={(event) =>
              updateAppearance({
                backgroundType: event.target.value as CorraBackgroundType,
              })
            }
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          >
            <option value="gradient">Gradient</option>
            <option value="solid">Solid Color</option>
            <option value="image">Image PNG/JPG/WebP</option>
            <option value="video">Video MP4 Loop</option>
          </select>
        </label>

        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">
            Background Fit
          </span>
          <select
            value={brandConfig.appearance.backgroundFit}
            onChange={(event) =>
              updateAppearance({
                backgroundFit: event.target.value as CorraBackgroundFit,
              })
            }
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          >
            <option value="cover">Cover</option>
            <option value="contain">Contain</option>
            <option value="fill">Fill</option>
          </select>
        </label>

        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">
            Background Opacity
          </span>
          <input
            value={brandConfig.appearance.backgroundOpacity}
            onChange={(event) =>
              updateAppearance({
                backgroundOpacity: Number(event.target.value),
              })
            }
            min={0}
            max={1}
            step={0.05}
            type="number"
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          />
        </label>

        <label className="space-y-2 md:col-span-2">
          <span className="text-xs font-black uppercase tracking-wider">
            Background Value
          </span>
          <input
            value={brandConfig.appearance.backgroundValue}
            onChange={(event) =>
              updateAppearance({
                backgroundValue: event.target.value,
              })
            }
            placeholder="corra-asset://... / URL / CSS gradient / color"
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          />
        </label>
      </div>

      <div className="mt-5 flex flex-col sm:flex-row gap-3">
        <button
          type="button"
          onClick={handlePickLocalBackground}
          disabled={!canPickLocalBackground}
          className="rounded-2xl bg-[var(--corra-primary)] px-5 py-3 text-sm font-black text-white disabled:opacity-50"
        >
          Pick Local PNG/JPG/WebP/MP4
        </button>

        <button
          type="button"
          onClick={resetBrandConfig}
          className="rounded-2xl border border-[var(--corra-border)] bg-white px-5 py-3 text-sm font-black text-[var(--corra-text)]"
        >
          Reset to Default
        </button>
      </div>

      {!canPickLocalBackground && (
        <p className="mt-3 text-xs text-[var(--corra-muted)]">
          Local file picker is only available inside Electron desktop. Browser
          preview can still use URL, CSS color, or CSS gradient manually.
        </p>
      )}

      {message && (
        <div className="mt-4 rounded-2xl border border-[var(--corra-border)] bg-white/70 p-3 text-xs font-bold text-[var(--corra-muted)]">
          {message}
        </div>
      )}
    </div>
  );
}
TSX

echo ""
echo "Writing docs..."

write_file "docs/phase-7e1-local-background-picker.md" <<'MD'
# Phase 7E1 - Local Background Picker

## Added

- Electron local file picker for UI backgrounds
- Supported files:
  - PNG
  - JPG/JPEG
  - WebP
  - MP4
- Selected file is copied into Electron userData brand-assets folder
- Renderer uses corra-asset:// custom protocol
- Admin BrandAppearancePanel can pick local background assets

## Usage

In Electron desktop:

1. Open Admin Panel
2. Open Brand & Appearance
3. Click Pick Local PNG/JPG/WebP/MP4
4. Select file
5. Background updates

## Browser Preview

Codespaces/browser preview cannot open local file picker.
Use Electron desktop for this phase.
MD

echo ""
echo "Verifying..."

grep -q "corra:asset-pick-background" apps/desktop-electron/electron/main/index.cjs || fail "Electron main missing asset IPC."
grep -q "protocol.registerSchemesAsPrivileged" apps/desktop-electron/electron/main/index.cjs || fail "Electron main missing asset protocol."
grep -q "pickBackground" apps/desktop-electron/electron/preload/preload.cjs || fail "Preload missing pickBackground."
[ -f "apps/booth-ui/src/lib/desktop-assets.ts" ] || fail "Missing desktop-assets helper."
grep -q "Pick Local PNG" apps/booth-ui/src/components/admin/BrandAppearancePanel.tsx || fail "BrandAppearancePanel missing local picker button."

echo ""
echo "========================================"
echo " Phase 7E1 completed."
echo "========================================"
echo ""
echo "Next:"
echo "  pnpm --filter @corra/booth-ui typecheck"
echo "  git add ."
echo "  git commit -m \"feat: add local background picker\""
echo "  git push origin main"
echo ""
