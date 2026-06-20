#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9A3R - Electron Print Handler"
echo "========================================"

# 1. Patch UI print bridge fallback.
BRIDGE="apps/booth-ui/src/camera/print-bridge.ts"

[ -f "$BRIDGE" ] || {
  echo "ERROR: $BRIDGE not found. Run 9A3Q first."
  exit 1
}

cat > "$BRIDGE" <<'TS'
export type CameraPrintBridgeInput = {
  jobId: string;
  dataUrl: string;
  widthPx: number;
  heightPx: number;
  copies: number;
  templateName: string;
  renderMode: string;
};

export type CameraPrintBridgeResult = {
  ok: boolean;
  jobId?: string;
  printerName?: string;
  message?: string;
  error?: string;
};

type CorraPrintBridge = {
  printImageDataUrl?: (
    input: CameraPrintBridgeInput,
  ) => Promise<CameraPrintBridgeResult>;
};

type CorraWindow = Window & {
  corra?: {
    print?: CorraPrintBridge;
  };
  corraPrintBridge?: CorraPrintBridge;
};

export function getCameraPrintBridge(): CorraPrintBridge | null {
  if (typeof window === 'undefined') return null;

  const maybeWindow = window as CorraWindow;

  return maybeWindow.corra?.print || maybeWindow.corraPrintBridge || null;
}

export function isCameraPrintBridgeAvailable(): boolean {
  return Boolean(getCameraPrintBridge()?.printImageDataUrl);
}

export async function printImageThroughBridge(
  input: CameraPrintBridgeInput,
): Promise<CameraPrintBridgeResult> {
  const bridge = getCameraPrintBridge();

  if (!bridge?.printImageDataUrl) {
    return {
      ok: false,
      jobId: input.jobId,
      error:
        'Electron print bridge is not available. Run inside Electron after the preload/main print handler is added.',
    };
  }

  try {
    return await bridge.printImageDataUrl(input);
  } catch (error) {
    return {
      ok: false,
      jobId: input.jobId,
      error:
        error instanceof Error
          ? error.message
          : 'Unknown print bridge error.',
    };
  }
}
TS

# 2. Locate Electron preload file.
PRELOAD_FILE="${CORRA_ELECTRON_PRELOAD_FILE:-}"

if [ -z "$PRELOAD_FILE" ]; then
  PRELOAD_FILE="$(find apps/desktop-electron -maxdepth 5 -type f \( -name '*.js' -o -name '*.cjs' -o -name '*.ts' \) -print 2>/dev/null | xargs grep -l "contextBridge" 2>/dev/null | head -n 1 || true)"
fi

[ -n "$PRELOAD_FILE" ] && [ -f "$PRELOAD_FILE" ] || {
  echo "ERROR: Could not find Electron preload file."
  echo "Set manually then rerun, example:"
  echo "CORRA_ELECTRON_PRELOAD_FILE=apps/desktop-electron/preload/index.js ./scripts/phase-9a3r-electron-print-handler.sh"
  exit 1
}

# 3. Locate Electron main file.
MAIN_FILE="${CORRA_ELECTRON_MAIN_FILE:-}"

if [ -z "$MAIN_FILE" ]; then
  MAIN_FILE="$(find apps/desktop-electron -maxdepth 5 -type f \( -name '*.js' -o -name '*.cjs' -o -name '*.ts' \) -print 2>/dev/null | xargs grep -l "ipcMain" 2>/dev/null | head -n 1 || true)"
fi

[ -n "$MAIN_FILE" ] && [ -f "$MAIN_FILE" ] || {
  echo "ERROR: Could not find Electron main file."
  echo "Set manually then rerun, example:"
  echo "CORRA_ELECTRON_MAIN_FILE=apps/desktop-electron/main/index.js ./scripts/phase-9a3r-electron-print-handler.sh"
  exit 1
}

echo "Preload file: $PRELOAD_FILE"
echo "Main file   : $MAIN_FILE"

# 4. Append preload bridge.
if ! grep -q "corraPrintBridge" "$PRELOAD_FILE"; then
cat >> "$PRELOAD_FILE" <<'JS'

// Corra Booth print bridge
;(() => {
  try {
    const electronRuntime = require('electron');

    electronRuntime.contextBridge.exposeInMainWorld('corraPrintBridge', {
      printImageDataUrl: (input) =>
        electronRuntime.ipcRenderer.invoke('corra:print-image-data-url', input),
    });
  } catch (error) {
    console.error('[corra] failed to expose print bridge', error);
  }
})();
JS
fi

# 5. Append main IPC print handler.
if ! grep -q "corra:print-image-data-url" "$MAIN_FILE"; then
cat >> "$MAIN_FILE" <<'JS'

// Corra Booth image print handler
;(() => {
  try {
    const electronRuntime = require('electron');

    if (global.__corraPrintImageHandlerRegistered) {
      return;
    }

    global.__corraPrintImageHandlerRegistered = true;

    function escapeHtml(value) {
      return String(value || '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
    }

    function normalizeCopies(value) {
      const numberValue = Number(value);

      if (!Number.isFinite(numberValue)) return 1;

      return Math.max(1, Math.min(20, Math.floor(numberValue)));
    }

    electronRuntime.ipcMain.handle(
      'corra:print-image-data-url',
      async (_event, input) => {
        const jobId = String(input?.jobId || '');
        const dataUrl = String(input?.dataUrl || '');
        const widthPx = Number(input?.widthPx || 0);
        const heightPx = Number(input?.heightPx || 0);
        const copies = normalizeCopies(input?.copies);
        const templateName = escapeHtml(input?.templateName || 'Corra Booth Print');

        if (!jobId) {
          return {
            ok: false,
            error: 'Missing print job id.',
          };
        }

        if (!dataUrl.startsWith('data:image/')) {
          return {
            ok: false,
            jobId,
            error: 'Invalid image data URL.',
          };
        }

        const printWindow = new electronRuntime.BrowserWindow({
          width: Math.max(800, widthPx || 800),
          height: Math.max(600, heightPx || 600),
          show: false,
          webPreferences: {
            sandbox: true,
            contextIsolation: true,
            nodeIntegration: false,
          },
        });

        const html = `
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>${templateName}</title>
    <style>
      html,
      body {
        width: 100%;
        height: 100%;
        margin: 0;
        padding: 0;
        background: white;
      }

      body {
        display: grid;
        place-items: center;
      }

      img {
        display: block;
        width: 100vw;
        height: 100vh;
        object-fit: contain;
      }

      @page {
        margin: 0;
      }
    </style>
  </head>
  <body>
    <img src="${dataUrl}" alt="${templateName}" />
  </body>
</html>`;

        try {
          await printWindow.loadURL(
            `data:text/html;charset=utf-8,${encodeURIComponent(html)}`,
          );

          await new Promise((resolve) => setTimeout(resolve, 500));

          const printers = await printWindow.webContents.getPrintersAsync();
          const defaultPrinter =
            printers.find((printer) => printer.isDefault) || printers[0];

          const result = await new Promise((resolve) => {
            printWindow.webContents.print(
              {
                silent: false,
                printBackground: true,
                copies,
              },
              (success, failureReason) => {
                resolve({
                  ok: success,
                  jobId,
                  printerName: defaultPrinter?.name,
                  message: success
                    ? `Print dialog sent for ${copies} copy/copies.`
                    : undefined,
                  error: success
                    ? undefined
                    : failureReason || 'Electron print failed.',
                });
              },
            );
          });

          return result;
        } catch (error) {
          return {
            ok: false,
            jobId,
            error:
              error instanceof Error
                ? error.message
                : 'Unknown Electron print error.',
          };
        } finally {
          if (!printWindow.isDestroyed()) {
            printWindow.close();
          }
        }
      },
    );
  } catch (error) {
    console.error('[corra] failed to register print handler', error);
  }
})();
JS
fi

echo ""
echo "Relevant lines:"
grep -R "corraPrintBridge\\|corra:print-image-data-url\\|printImageDataUrl" -n "$PRELOAD_FILE" "$MAIN_FILE" "$BRIDGE" || true

echo ""
echo "9A3R done."
