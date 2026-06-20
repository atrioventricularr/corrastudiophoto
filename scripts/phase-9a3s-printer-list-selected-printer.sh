#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9A3S - Printer List + Selected Printer"
echo "========================================"

BRIDGE="apps/booth-ui/src/camera/print-bridge.ts"
PANEL="apps/booth-ui/src/camera/CameraPrintQueuePanel.tsx"

[ -f "$BRIDGE" ] || {
  echo "ERROR: $BRIDGE not found. Run 9A3Q/9A3R first."
  exit 1
}

[ -f "$PANEL" ] || {
  echo "ERROR: $PANEL not found. Run 9A3P first."
  exit 1
}

cat > "$BRIDGE" <<'TS'
export type CameraPrinterInfo = {
  name: string;
  displayName?: string;
  description?: string;
  status?: number;
  isDefault?: boolean;
};

export type CameraPrintBridgeInput = {
  jobId: string;
  dataUrl: string;
  widthPx: number;
  heightPx: number;
  copies: number;
  templateName: string;
  renderMode: string;
  printerName?: string;
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
  listPrinters?: () => Promise<CameraPrinterInfo[]>;
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

export async function listPrintersThroughBridge(): Promise<CameraPrinterInfo[]> {
  const bridge = getCameraPrintBridge();

  if (!bridge?.listPrinters) {
    return [];
  }

  try {
    return await bridge.listPrinters();
  } catch {
    return [];
  }
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

cat > "$PANEL" <<'TSX'
import React, {
  useEffect,
  useState,
} from 'react';
import {
  isCameraPrintBridgeAvailable,
  listPrintersThroughBridge,
  printImageThroughBridge,
  type CameraPrinterInfo,
} from './print-bridge';
import { useCameraPrintQueue } from './CameraPrintQueueProvider';
import {
  type CameraRenderOutput,
  useCameraRenderOutput,
} from './CameraRenderOutputProvider';

function formatTime(value: string) {
  return new Intl.DateTimeFormat('id-ID', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    day: '2-digit',
    month: 'short',
  }).format(new Date(value));
}

function downloadOutput(output: CameraRenderOutput) {
  const safeTemplateName = output.templateName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');

  const link = document.createElement('a');
  link.href = output.dataUrl;
  link.download = `${safeTemplateName || 'corra'}-print-candidate.png`;
  document.body.appendChild(link);
  link.click();
  link.remove();
}

export function CameraPrintQueuePanel() {
  const { printCandidateOutput } = useCameraRenderOutput();
  const {
    printJobs,
    enqueuePrintJob,
    updatePrintJobStatus,
    removePrintJob,
    clearPrintJobs,
  } = useCameraPrintQueue();

  const [copies, setCopies] = useState(1);
  const [printingJobId, setPrintingJobId] = useState('');
  const [printers, setPrinters] = useState<CameraPrinterInfo[]>([]);
  const [selectedPrinterName, setSelectedPrinterName] = useState('');
  const [printerListStatus, setPrinterListStatus] = useState('');

  const bridgeAvailable = isCameraPrintBridgeAvailable();

  const refreshPrinters = async () => {
    setPrinterListStatus('Loading printers...');

    const printerList = await listPrintersThroughBridge();

    setPrinters(printerList);

    const defaultPrinter = printerList.find((printer) => printer.isDefault);

    setSelectedPrinterName((current) => {
      if (current && printerList.some((printer) => printer.name === current)) {
        return current;
      }

      return defaultPrinter?.name || printerList[0]?.name || '';
    });

    setPrinterListStatus(
      printerList.length > 0
        ? `${printerList.length} printer(s) found.`
        : bridgeAvailable
          ? 'No printers found from Electron.'
          : 'Bridge missing.',
    );
  };

  useEffect(() => {
    if (!bridgeAvailable) {
      setPrinters([]);
      setSelectedPrinterName('');
      setPrinterListStatus('Bridge missing.');
      return;
    }

    void refreshPrinters();
  }, [bridgeAvailable]);

  const handleCreatePrintJob = () => {
    if (!printCandidateOutput) return;

    enqueuePrintJob({
      output: printCandidateOutput,
      copies,
    });
  };

  const handleCreateAndPrintJob = async () => {
    if (!printCandidateOutput) return;

    const job = enqueuePrintJob({
      output: printCandidateOutput,
      copies,
    });

    await handlePrintJob(job);
  };

  const handlePrintJob = async (job: {
    id: string;
    dataUrl: string;
    widthPx: number;
    heightPx: number;
    copies: number;
    templateName: string;
    renderMode: string;
  }) => {
    setPrintingJobId(job.id);
    updatePrintJobStatus(job.id, 'printing');

    const result = await printImageThroughBridge({
      jobId: job.id,
      dataUrl: job.dataUrl,
      widthPx: job.widthPx,
      heightPx: job.heightPx,
      copies: job.copies,
      templateName: job.templateName,
      renderMode: job.renderMode,
      printerName: selectedPrinterName || undefined,
    });

    if (result.ok) {
      updatePrintJobStatus(job.id, 'completed');
    } else {
      updatePrintJobStatus(
        job.id,
        'failed',
        result.error || 'Print bridge failed.',
      );
    }

    setPrintingJobId('');
  };

  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Local Print Queue
          </p>
          <h4 className="mt-1 text-xl font-black text-slate-950">
            Print Job Candidate
          </h4>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Queue lokal sementara untuk output yang sudah ditandai sebagai print candidate.
          </p>
        </div>

        <div className="flex flex-wrap gap-2">
          <span className="rounded-full bg-slate-950 px-3 py-1 text-xs font-black text-white">
            {printJobs.length} jobs
          </span>

          <span
            className={`rounded-full px-3 py-1 text-xs font-black text-white ${
              bridgeAvailable ? 'bg-emerald-600' : 'bg-amber-500'
            }`}
          >
            {bridgeAvailable ? 'Bridge ready' : 'Bridge missing'}
          </span>

          {selectedPrinterName && (
            <span className="rounded-full bg-blue-600 px-3 py-1 text-xs font-black text-white">
              {selectedPrinterName}
            </span>
          )}
        </div>
      </div>

      <div className="mt-4 rounded-3xl border border-slate-100 bg-slate-50 p-4">
        <div className="grid gap-3 sm:grid-cols-[1fr_160px] sm:items-end">
          <label className="block">
            <span className="text-xs font-black uppercase tracking-wider text-slate-400">
              Selected Printer
            </span>
            <select
              value={selectedPrinterName}
              onChange={(event) => setSelectedPrinterName(event.target.value)}
              disabled={!bridgeAvailable || printers.length === 0}
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none disabled:opacity-50"
            >
              <option value="">
                {printers.length === 0 ? 'No printer detected' : 'Use default printer'}
              </option>

              {printers.map((printer) => (
                <option key={printer.name} value={printer.name}>
                  {printer.name}
                  {printer.isDefault ? ' · Default' : ''}
                </option>
              ))}
            </select>
          </label>

          <button
            type="button"
            onClick={() => void refreshPrinters()}
            disabled={!bridgeAvailable}
            className="rounded-2xl border border-slate-200 bg-white px-4 py-3 text-xs font-black text-slate-700 disabled:opacity-40"
          >
            Refresh Printers
          </button>
        </div>

        <p className="mt-3 text-xs font-bold text-slate-500">
          {printerListStatus}
        </p>
      </div>

      {!bridgeAvailable && (
        <div className="mt-4 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm font-bold text-amber-800">
          Print bridge belum tersedia di environment ini. Ini normal kalau masih
          buka lewat browser/Codespaces. Jalankan app lewat Electron untuk list
          printer OS.
        </div>
      )}

      {printCandidateOutput ? (
        <div className="mt-4 rounded-3xl border border-blue-100 bg-blue-50 p-4">
          <div className="grid gap-4 lg:grid-cols-[160px_1fr]">
            <img
              src={printCandidateOutput.dataUrl}
              alt="Print candidate"
              className="h-40 w-full rounded-2xl border border-blue-100 bg-white object-contain"
            />

            <div>
              <p className="text-xs font-black uppercase tracking-[0.2em] text-blue-400">
                Current Print Candidate
              </p>
              <h5 className="mt-1 text-lg font-black text-blue-950">
                {printCandidateOutput.templateName}
              </h5>
              <p className="mt-1 text-sm font-bold text-blue-700">
                {printCandidateOutput.widthPx} × {printCandidateOutput.heightPx}px ·{' '}
                {printCandidateOutput.renderMode}
              </p>

              <div className="mt-4 grid gap-3 sm:grid-cols-[1fr_160px_160px_180px]">
                <label className="block">
                  <span className="text-xs font-black uppercase tracking-wider text-blue-400">
                    Copies
                  </span>
                  <select
                    value={copies}
                    onChange={(event) => setCopies(Number(event.target.value))}
                    className="mt-2 w-full rounded-2xl border border-blue-100 bg-white px-4 py-3 text-sm font-bold text-blue-950 outline-none"
                  >
                    <option value={1}>1 copy</option>
                    <option value={2}>2 copies</option>
                    <option value={3}>3 copies</option>
                    <option value={4}>4 copies</option>
                    <option value={5}>5 copies</option>
                  </select>
                </label>

                <button
                  type="button"
                  onClick={() => downloadOutput(printCandidateOutput)}
                  className="self-end rounded-2xl border border-blue-200 bg-white px-4 py-3 text-xs font-black text-blue-700"
                >
                  Download
                </button>

                <button
                  type="button"
                  onClick={handleCreatePrintJob}
                  className="self-end rounded-2xl bg-blue-600 px-4 py-3 text-xs font-black text-white"
                >
                  Create Job
                </button>

                <button
                  type="button"
                  onClick={() => void handleCreateAndPrintJob()}
                  disabled={Boolean(printingJobId)}
                  className="self-end rounded-2xl bg-slate-950 px-4 py-3 text-xs font-black text-white disabled:opacity-40"
                >
                  Create & Print
                </button>
              </div>
            </div>
          </div>
        </div>
      ) : (
        <div className="mt-4 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm font-bold text-amber-800">
          Belum ada print candidate. Pilih output di Session Final Output, lalu klik
          Mark as Print Candidate.
        </div>
      )}

      <div className="mt-4 flex items-center justify-between gap-3">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
          Queue History
        </p>

        <button
          type="button"
          onClick={clearPrintJobs}
          disabled={printJobs.length === 0}
          className="rounded-2xl border border-red-200 bg-red-50 px-4 py-2 text-xs font-black text-red-700 disabled:opacity-40"
        >
          Clear Queue
        </button>
      </div>

      <div className="mt-3 grid gap-3">
        {printJobs.length === 0 && (
          <div className="rounded-2xl bg-slate-50 p-4 text-sm font-bold text-slate-500">
            No print jobs yet.
          </div>
        )}

        {printJobs.map((job) => (
          <div
            key={job.id}
            className="grid gap-3 rounded-3xl border border-slate-100 bg-slate-50 p-3 lg:grid-cols-[96px_1fr_auto]"
          >
            <img
              src={job.dataUrl}
              alt={job.templateName}
              className="h-24 w-24 rounded-2xl border border-slate-200 bg-white object-cover"
            />

            <div>
              <div className="flex flex-wrap items-center gap-2">
                <h5 className="text-sm font-black text-slate-950">
                  {job.templateName}
                </h5>
                <span
                  className={`rounded-full px-3 py-1 text-[10px] font-black uppercase ${
                    job.status === 'completed'
                      ? 'bg-emerald-100 text-emerald-700'
                      : job.status === 'failed'
                        ? 'bg-red-100 text-red-700'
                        : job.status === 'printing'
                          ? 'bg-blue-100 text-blue-700'
                          : job.status === 'cancelled'
                            ? 'bg-slate-200 text-slate-600'
                            : 'bg-yellow-100 text-yellow-700'
                  }`}
                >
                  {job.status}
                </span>
              </div>

              <p className="mt-1 text-xs font-bold text-slate-500">
                {job.widthPx} × {job.heightPx}px · {job.renderMode} · {job.copies}{' '}
                copy{job.copies > 1 ? 'ies' : ''}
              </p>
              <p className="mt-1 text-xs font-bold text-slate-400">
                Created {formatTime(job.createdAt)}
              </p>

              {job.errorMessage && (
                <p className="mt-2 rounded-xl bg-red-50 px-3 py-2 text-xs font-bold text-red-700">
                  {job.errorMessage}
                </p>
              )}
            </div>

            <div className="grid gap-2 sm:grid-cols-2 lg:w-56 lg:grid-cols-1">
              <button
                type="button"
                onClick={() => void handlePrintJob(job)}
                disabled={Boolean(printingJobId)}
                className="rounded-2xl border border-slate-300 bg-white px-3 py-2 text-[10px] font-black text-slate-800 disabled:opacity-40"
              >
                {printingJobId === job.id ? 'Printing...' : 'Print via Bridge'}
              </button>

              <button
                type="button"
                onClick={() => updatePrintJobStatus(job.id, 'completed')}
                className="rounded-2xl border border-emerald-200 bg-white px-3 py-2 text-[10px] font-black text-emerald-700"
              >
                Mark Completed
              </button>

              <button
                type="button"
                onClick={() =>
                  updatePrintJobStatus(job.id, 'failed', 'Manual failure marker.')
                }
                className="rounded-2xl border border-red-200 bg-white px-3 py-2 text-[10px] font-black text-red-700"
              >
                Mark Failed
              </button>

              <button
                type="button"
                onClick={() => removePrintJob(job.id)}
                className="rounded-2xl border border-slate-200 bg-white px-3 py-2 text-[10px] font-black text-slate-700"
              >
                Remove
              </button>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
TSX

PRELOAD_FILE="${CORRA_ELECTRON_PRELOAD_FILE:-}"
if [ -z "$PRELOAD_FILE" ]; then
  PRELOAD_FILE="$(find apps/desktop-electron -maxdepth 5 -type f \( -name '*.js' -o -name '*.cjs' -o -name '*.ts' \) -print 2>/dev/null | xargs grep -l "corraPrintBridge\\|contextBridge" 2>/dev/null | head -n 1 || true)"
fi

MAIN_FILE="${CORRA_ELECTRON_MAIN_FILE:-}"
if [ -z "$MAIN_FILE" ]; then
  MAIN_FILE="$(find apps/desktop-electron -maxdepth 5 -type f \( -name '*.js' -o -name '*.cjs' -o -name '*.ts' \) -print 2>/dev/null | xargs grep -l "corra:print-image-data-url\\|ipcMain" 2>/dev/null | head -n 1 || true)"
fi

[ -n "$PRELOAD_FILE" ] && [ -f "$PRELOAD_FILE" ] || {
  echo "ERROR: Could not find Electron preload file."
  exit 1
}

[ -n "$MAIN_FILE" ] && [ -f "$MAIN_FILE" ] || {
  echo "ERROR: Could not find Electron main file."
  exit 1
}

echo "Preload file: $PRELOAD_FILE"
echo "Main file   : $MAIN_FILE"

python - <<PY
from pathlib import Path

preload = Path("$PRELOAD_FILE")
text = preload.read_text()

if "listPrinters" not in text:
    text = text.replace(
        "printImageDataUrl: (input) =>\n        electronRuntime.ipcRenderer.invoke('corra:print-image-data-url', input),",
        "printImageDataUrl: (input) =>\n        electronRuntime.ipcRenderer.invoke('corra:print-image-data-url', input),\n      listPrinters: () =>\n        electronRuntime.ipcRenderer.invoke('corra:list-printers'),",
    )

preload.write_text(text)
print("PATCH:", preload)
PY

python - <<PY
from pathlib import Path

main = Path("$MAIN_FILE")
text = main.read_text()

if "corra:list-printers" not in text:
    text += r'''

// Corra Booth printer list handler
;(() => {
  try {
    const electronRuntime = require('electron');

    if (global.__corraListPrintersHandlerRegistered) {
      return;
    }

    global.__corraListPrintersHandlerRegistered = true;

    electronRuntime.ipcMain.handle('corra:list-printers', async (event) => {
      const ownerWindow =
        electronRuntime.BrowserWindow.fromWebContents(event.sender) ||
        electronRuntime.BrowserWindow.getFocusedWindow();

      if (!ownerWindow) {
        return [];
      }

      const printers = await ownerWindow.webContents.getPrintersAsync();

      return printers.map((printer) => ({
        name: printer.name,
        displayName: printer.displayName,
        description: printer.description,
        status: printer.status,
        isDefault: Boolean(printer.isDefault),
      }));
    });
  } catch (error) {
    console.error('[corra] failed to register printer list handler', error);
  }
})();
'''

# Patch print handler to use requested printer name if the previous handler exists.
if "const requestedPrinterName = String(input?.printerName || '');" not in text:
    text = text.replace(
        "const templateName = escapeHtml(input?.templateName || 'Corra Booth Print');",
        "const templateName = escapeHtml(input?.templateName || 'Corra Booth Print');\n        const requestedPrinterName = String(input?.printerName || '');",
        1,
    )

if "const selectedPrinter =" not in text:
    text = text.replace(
        "const defaultPrinter =\n            printers.find((printer) => printer.isDefault) || printers[0];",
        "const defaultPrinter =\n            printers.find((printer) => printer.isDefault) || printers[0];\n          const selectedPrinter =\n            printers.find((printer) => printer.name === requestedPrinterName) ||\n            defaultPrinter;",
        1,
    )

text = text.replace(
    "printerName: defaultPrinter?.name,",
    "printerName: selectedPrinter?.name,",
    1,
)

if "deviceName:" not in text:
    text = text.replace(
        "copies,\n              },",
        "copies,\n                ...(selectedPrinter?.name\n                  ? { deviceName: selectedPrinter.name }\n                  : {}),\n              },",
        1,
    )

main.write_text(text)
print("PATCH:", main)
PY

echo ""
echo "Relevant lines:"
grep -R "listPrinters\\|corra:list-printers\\|selectedPrinter\\|printerName" -n "$BRIDGE" "$PANEL" "$PRELOAD_FILE" "$MAIN_FILE" || true

echo ""
echo "9A3S done."
