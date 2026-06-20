#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9A3U - Silent Print Toggle"
echo "========================================"

BRIDGE="apps/booth-ui/src/camera/print-bridge.ts"
PANEL="apps/booth-ui/src/camera/CameraPrintQueuePanel.tsx"

[ -f "$BRIDGE" ] || {
  echo "ERROR: $BRIDGE not found. Run 9A3S first."
  exit 1
}

[ -f "$PANEL" ] || {
  echo "ERROR: $PANEL not found. Run 9A3S first."
  exit 1
}

python - <<'PY'
from pathlib import Path

bridge = Path("apps/booth-ui/src/camera/print-bridge.ts")
text = bridge.read_text()

if "silent?: boolean;" not in text:
    text = text.replace(
        "  printerName?: string;\n};",
        "  printerName?: string;\n  silent?: boolean;\n};",
        1,
    )

bridge.write_text(text)
print("PATCH:", bridge)
PY

python - <<'PY'
from pathlib import Path

panel = Path("apps/booth-ui/src/camera/CameraPrintQueuePanel.tsx")
text = panel.read_text()

# Add state.
if "silentPrint" not in text:
    text = text.replace(
        "  const [printerListStatus, setPrinterListStatus] = useState('');",
        "  const [printerListStatus, setPrinterListStatus] = useState('');\n  const [silentPrint, setSilentPrint] = useState(false);",
        1,
    )

# Pass silent flag into bridge call.
if "silent: silentPrint" not in text:
    text = text.replace(
        "      printerName: selectedPrinterName || undefined,\n    });",
        "      printerName: selectedPrinterName || undefined,\n      silent: silentPrint,\n    });",
        1,
    )

# Add print mode UI under printer selector.
marker = """        <p className="mt-3 text-xs font-bold text-slate-500">
          {printerListStatus}
        </p>
      </div>"""

insert = """        <p className="mt-3 text-xs font-bold text-slate-500">
          {printerListStatus}
        </p>

        <div className="mt-4 rounded-2xl border border-slate-200 bg-white p-3">
          <p className="text-xs font-black uppercase tracking-wider text-slate-400">
            Print Mode
          </p>

          <div className="mt-3 grid gap-3 sm:grid-cols-2">
            <button
              type="button"
              onClick={() => setSilentPrint(false)}
              className={`rounded-2xl px-4 py-3 text-xs font-black ${
                !silentPrint
                  ? 'bg-slate-950 text-white'
                  : 'border border-slate-200 bg-slate-50 text-slate-700'
              }`}
            >
              Show Print Dialog
            </button>

            <button
              type="button"
              onClick={() => setSilentPrint(true)}
              className={`rounded-2xl px-4 py-3 text-xs font-black ${
                silentPrint
                  ? 'bg-slate-950 text-white'
                  : 'border border-slate-200 bg-slate-50 text-slate-700'
              }`}
            >
              Silent Print
            </button>
          </div>

          <p className="mt-3 text-xs font-bold text-slate-500">
            {silentPrint
              ? 'Silent print akan langsung kirim ke selected/default printer tanpa dialog.'
              : 'Print dialog akan muncul dulu sebelum user konfirmasi print.'}
          </p>
        </div>
      </div>"""

if "Show Print Dialog" not in text:
    if marker not in text:
        raise SystemExit("Could not find printer status marker.")
    text = text.replace(marker, insert, 1)

# Add mode text in queue job details.
if "Mode: {silentPrint ? 'Silent Print' : 'Print Dialog'}" not in text:
    text = text.replace(
        "{selectedPrinterName && (\n            <span className=\"rounded-full bg-blue-600 px-3 py-1 text-xs font-black text-white\">\n              {selectedPrinterName}\n            </span>\n          )}",
        "{selectedPrinterName && (\n            <span className=\"rounded-full bg-blue-600 px-3 py-1 text-xs font-black text-white\">\n              {selectedPrinterName}\n            </span>\n          )}\n\n          <span className=\"rounded-full bg-purple-600 px-3 py-1 text-xs font-black text-white\">\n            {silentPrint ? 'Silent Print' : 'Print Dialog'}\n          </span>",
        1,
    )

panel.write_text(text)
print("PATCH:", panel)
PY

PRELOAD_FILE="${CORRA_ELECTRON_PRELOAD_FILE:-}"
if [ -z "$PRELOAD_FILE" ]; then
  PRELOAD_FILE="$(find apps/desktop-electron -maxdepth 5 -type f \( -name '*.js' -o -name '*.cjs' -o -name '*.ts' \) -print 2>/dev/null | xargs grep -l "corraPrintBridge\\|contextBridge" 2>/dev/null | head -n 1 || true)"
fi

MAIN_FILE="${CORRA_ELECTRON_MAIN_FILE:-}"
if [ -z "$MAIN_FILE" ]; then
  MAIN_FILE="$(find apps/desktop-electron -maxdepth 5 -type f \( -name '*.js' -o -name '*.cjs' -o -name '*.ts' \) -print 2>/dev/null | xargs grep -l "corra:print-image-data-url\\|ipcMain" 2>/dev/null | head -n 1 || true)"
fi

[ -n "$MAIN_FILE" ] && [ -f "$MAIN_FILE" ] || {
  echo "ERROR: Could not find Electron main file."
  echo "UI files patched. Set CORRA_ELECTRON_MAIN_FILE manually if needed."
  exit 1
}

echo "Main file: $MAIN_FILE"

python - <<PY
from pathlib import Path

main = Path("$MAIN_FILE")
text = main.read_text()

if "const requestedSilentPrint = Boolean(input?.silent);" not in text:
    if "const requestedPrinterName = String(input?.printerName || '');" in text:
        text = text.replace(
            "const requestedPrinterName = String(input?.printerName || '');",
            "const requestedPrinterName = String(input?.printerName || '');\n        const requestedSilentPrint = Boolean(input?.silent);",
            1,
        )
    else:
        raise SystemExit("Could not find requestedPrinterName line in Electron main print handler.")

text = text.replace(
    "silent: false,",
    "silent: requestedSilentPrint,",
    1,
)

text = text.replace(
    "message: success\n                    ? `Print dialog sent for ${copies} copy/copies.`\n                    : undefined,",
    "message: success\n                    ? requestedSilentPrint\n                      ? `Silent print sent for ${copies} copy/copies.`\n                      : `Print dialog sent for ${copies} copy/copies.`\n                    : undefined,",
    1,
)

main.write_text(text)
print("PATCH:", main)
PY

echo ""
echo "Relevant lines:"
grep -R "silent\\|Silent Print\\|Print Dialog\\|requestedSilentPrint" -n "$BRIDGE" "$PANEL" "$MAIN_FILE" || true

echo ""
echo "9A3U done."
