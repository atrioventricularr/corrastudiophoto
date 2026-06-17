#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - Phase 8B1 Static QRIS Picker"
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

[ -f "apps/desktop-electron/electron/main/index.cjs" ] || fail "Electron main not found."
[ -f "apps/desktop-electron/electron/preload/preload.cjs" ] || fail "Electron preload not found."
[ -f "apps/booth-ui/src/lib/desktop-assets.ts" ] || fail "desktop-assets.ts not found. Run 7E1 first."
[ -f "apps/booth-ui/src/components/admin/PaymentSettingsPanel.tsx" ] || fail "PaymentSettingsPanel not found. Run 8A1/8A2 first."

grep -q "function getAssetDirectory" apps/desktop-electron/electron/main/index.cjs || fail "Asset helper missing in Electron main. Run 7E1 first."
grep -q "corra:asset-pick-background" apps/desktop-electron/electron/main/index.cjs || fail "Background picker IPC missing. Run 7E1 first."

echo ""
echo "Patching Electron main for QRIS picker..."

python - <<'PY'
from pathlib import Path

path = Path("apps/desktop-electron/electron/main/index.cjs")
text = path.read_text()

qris_function = r'''
function isSupportedQrisExtension(filePath) {
  const ext = path.extname(filePath).toLowerCase();

  return [".png", ".jpg", ".jpeg", ".webp"].includes(ext);
}

async function pickQrisAsset() {
  const result = await dialog.showOpenDialog(mainWindow, {
    title: "Choose Static QRIS Image",
    properties: ["openFile"],
    filters: [
      {
        name: "QRIS Images",
        extensions: ["png", "jpg", "jpeg", "webp"],
      },
    ],
  });

  if (result.canceled || !result.filePaths.length) {
    return {
      cancelled: true,
    };
  }

  const sourcePath = result.filePaths[0];

  if (!isSupportedQrisExtension(sourcePath)) {
    return {
      cancelled: true,
      error: "Unsupported QRIS file. Use PNG, JPG, JPEG, or WebP.",
    };
  }

  const kind = "qris";
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
  };
}
'''

if "function pickQrisAsset()" not in text:
    marker = "function registerIpcHandlers() {"
    if marker not in text:
        raise SystemExit("Could not find registerIpcHandlers marker.")
    text = text.replace(marker, qris_function + "\n" + marker)

if 'corra:asset-pick-qris' not in text:
    marker = '''  ipcMain.handle("corra:asset-pick-background", async () => {
    try {
      return await pickBackgroundAsset();
    } catch (error) {
      return {
        cancelled: true,
        error: error instanceof Error ? error.message : "Unknown asset picker error",
      };
    }
  });'''

    insert = marker + '''

  ipcMain.handle("corra:asset-pick-qris", async () => {
    try {
      return await pickQrisAsset();
    } catch (error) {
      return {
        cancelled: true,
        error: error instanceof Error ? error.message : "Unknown QRIS picker error",
      };
    }
  });'''

    if marker not in text:
      raise SystemExit("Could not find background picker IPC block.")
    text = text.replace(marker, insert)

path.write_text(text)
print("PATCH file: apps/desktop-electron/electron/main/index.cjs")
PY

echo ""
echo "Patching Electron preload assets bridge..."

python - <<'PY'
from pathlib import Path

path = Path("apps/desktop-electron/electron/preload/preload.cjs")
text = path.read_text()

if "pickQris" not in text:
    text = text.replace(
        '''  assets: {
    pickBackground: () => ipcRenderer.invoke("corra:asset-pick-background"),
  },''',
        '''  assets: {
    pickBackground: () => ipcRenderer.invoke("corra:asset-pick-background"),
    pickQris: () => ipcRenderer.invoke("corra:asset-pick-qris"),
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

export type CorraPickedQrisAsset = {
  cancelled: boolean;
  error?: string;
  sourcePath?: string;
  targetPath?: string;
  filename?: string;
  url?: string;
};

export function isDesktopBackgroundPickerAvailable(): boolean {
  return typeof window !== 'undefined' && Boolean(window.corraDesktop?.assets?.pickBackground);
}

export function isDesktopQrisPickerAvailable(): boolean {
  return typeof window !== 'undefined' && Boolean(window.corraDesktop?.assets?.pickQris);
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

export async function pickDesktopQrisAsset(): Promise<CorraPickedQrisAsset> {
  if (!window.corraDesktop?.assets?.pickQris) {
    return {
      cancelled: true,
      error: 'Desktop QRIS picker is only available inside Electron.',
    };
  }

  return window.corraDesktop.assets.pickQris();
}
TS

echo ""
echo "Updating corra-desktop global types..."

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/types/corra-desktop.d.ts")
text = path.read_text()

if "type CorraPickedQrisAsset" not in text:
    marker = "  interface Window {"
    qris_type = """  type CorraPickedQrisAsset = {
    cancelled: boolean;
    error?: string;
    sourcePath?: string;
    targetPath?: string;
    filename?: string;
    url?: string;
  };

"""
    if marker not in text:
        raise SystemExit("Could not find Window interface marker.")
    text = text.replace(marker, qris_type + marker)

if "pickQris" not in text:
    text = text.replace(
        "        pickBackground: () => Promise<CorraPickedBackgroundAsset>;",
        "        pickBackground: () => Promise<CorraPickedBackgroundAsset>;\n        pickQris: () => Promise<CorraPickedQrisAsset>;"
    )

path.write_text(text)
print("PATCH file: apps/booth-ui/src/types/corra-desktop.d.ts")
PY

echo ""
echo "Patching PaymentSettingsPanel for QRIS picker..."

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/admin/PaymentSettingsPanel.tsx")
text = path.read_text()

if "pickDesktopQrisAsset" not in text:
    text = text.replace(
        "import {\n  deleteDesktopSecret,",
        "import {\n  deleteDesktopSecret,"
    )

    secure_import = "import {\n  deleteDesktopSecret,\n  getDesktopSecretStatus,\n  isDesktopSecureVaultAvailable,\n  setDesktopSecret,\n  type CorraSecretStatus,\n} from '../../lib/desktop-secure-vault';"

    asset_import = secure_import + "\nimport {\n  isDesktopQrisPickerAvailable,\n  pickDesktopQrisAsset,\n} from '../../lib/desktop-assets';"

    if secure_import not in text:
        raise SystemExit("Could not find secure vault import block.")
    text = text.replace(secure_import, asset_import)

if "const qrisPickerAvailable" not in text:
    text = text.replace(
        "  const vaultAvailable = isDesktopSecureVaultAvailable();",
        "  const vaultAvailable = isDesktopSecureVaultAvailable();\n  const qrisPickerAvailable = isDesktopQrisPickerAvailable();"
    )

if "handlePickQrisImage" not in text:
    needle = """  const updateStaticQris = (
    patch: Partial<typeof paymentConfig.staticQris>,
  ) => {
    updatePaymentConfig({
      staticQris: {
        ...paymentConfig.staticQris,
        ...patch,
      },
    });
  };

"""
    insert = needle + """  const handlePickQrisImage = async () => {
    setMessage('');

    const result = await pickDesktopQrisAsset();

    if (result.cancelled) {
      if (result.error) {
        setMessage(result.error);
      }

      return;
    }

    if (!result.url) {
      setMessage('QRIS file selected, but no usable asset URL was returned.');
      return;
    }

    updateStaticQris({
      imageUrl: result.url,
      merchantName:
        paymentConfig.staticQris.merchantName || paymentConfig.merchantName,
    });

    setMessage(`QRIS image selected: ${result.filename || result.url}`);
  };

"""
    if needle not in text:
        raise SystemExit("Could not find updateStaticQris block.")
    text = text.replace(needle, insert)

if "Pick QRIS PNG" not in text:
    start = text.index("{paymentConfig.provider === 'STATIC_QRIS'")
    end = text.index("{paymentConfig.provider === 'DOKU_QRIS'", start)
    block = text[start:end]

    closing = "          </div>\n        </div>\n      )}"
    qris_ui = """          </div>

          <div className="mt-4 flex flex-col sm:flex-row gap-3">
            <button
              type="button"
              onClick={handlePickQrisImage}
              disabled={!qrisPickerAvailable}
              className="rounded-2xl bg-[var(--corra-primary)] px-5 py-3 text-sm font-black text-white disabled:opacity-50"
            >
              Pick QRIS PNG/JPG/WebP
            </button>
          </div>

          {!qrisPickerAvailable && (
            <p className="mt-3 text-xs text-[var(--corra-muted)]">
              QRIS local picker is only available inside Electron desktop.
              Browser preview can still use image URL manually.
            </p>
          )}

          {paymentConfig.staticQris.imageUrl && (
            <div className="mt-4 rounded-2xl border border-[var(--corra-border)] bg-white p-4">
              <p className="mb-3 text-xs font-black uppercase tracking-wider text-[var(--corra-muted)]">
                QRIS Preview
              </p>
              <img
                src={paymentConfig.staticQris.imageUrl}
                alt="Static QRIS Preview"
                className="max-h-72 rounded-2xl border border-[var(--corra-border)] bg-white object-contain"
              />
            </div>
          )}
        </div>
      )}"""

    if closing not in block:
        raise SystemExit("Could not find Static QRIS block closing.")

    block = block.replace(closing, qris_ui, 1)
    text = text[:start] + block + text[end:]

path.write_text(text)
print("PATCH file: apps/booth-ui/src/components/admin/PaymentSettingsPanel.tsx")
PY

echo ""
echo "Writing docs..."

write_file "docs/phase-8b1-static-qris-picker.md" <<'MD'
# Phase 8B1 - Static QRIS Picker

## Added

- Electron QRIS image picker
- Supported files:
  - PNG
  - JPG/JPEG
  - WebP
- Selected QRIS image is copied into Electron userData brand-assets/qris
- Renderer receives corra-asset://qris/... URL
- Payment Settings Static QRIS can pick local QRIS file
- QRIS preview in Admin Panel

## Usage

In Electron desktop:

1. Open Admin Panel
2. Open Payment Settings
3. Choose Static QRIS PNG
4. Click Pick QRIS PNG/JPG/WebP
5. Select QRIS image
6. QRIS Image URL updates automatically
MD

echo ""
echo "Verifying..."

grep -q "corra:asset-pick-qris" apps/desktop-electron/electron/main/index.cjs || fail "Electron main missing QRIS IPC."
grep -q "pickQris" apps/desktop-electron/electron/preload/preload.cjs || fail "Preload missing pickQris."
grep -q "pickDesktopQrisAsset" apps/booth-ui/src/lib/desktop-assets.ts || fail "desktop-assets missing QRIS helper."
grep -q "Pick QRIS PNG" apps/booth-ui/src/components/admin/PaymentSettingsPanel.tsx || fail "PaymentSettingsPanel missing QRIS picker button."

echo ""
echo "========================================"
echo " Phase 8B1 completed."
echo "========================================"
echo ""
echo "Next:"
echo "  pnpm --filter @corra/booth-ui typecheck"
echo "  git add ."
echo "  git commit -m \"feat: add static qris picker\""
echo "  git push origin main"
echo ""
