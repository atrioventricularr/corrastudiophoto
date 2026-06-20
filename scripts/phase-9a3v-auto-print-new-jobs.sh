#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9A3V - Auto Print New Jobs"
echo "========================================"

PANEL="apps/booth-ui/src/camera/CameraPrintQueuePanel.tsx"

[ -f "$PANEL" ] || {
  echo "ERROR: $PANEL not found. Run 9A3U first."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/camera/CameraPrintQueuePanel.tsx")
text = path.read_text()

# 1. Add auto-print state.
if "autoPrintNewJobs" not in text:
    text = text.replace(
        "  const [silentPrint, setSilentPrint] = useState(false);",
        "  const [silentPrint, setSilentPrint] = useState(false);\n  const [autoPrintNewJobs, setAutoPrintNewJobs] = useState(false);",
        1,
    )

# 2. Patch Create Job behavior.
old = """  const handleCreatePrintJob = () => {
    if (!printCandidateOutput) return;

    enqueuePrintJob({
      output: printCandidateOutput,
      copies,
    });
  };"""

new = """  const handleCreatePrintJob = () => {
    if (!printCandidateOutput) return;

    const job = enqueuePrintJob({
      output: printCandidateOutput,
      copies,
    });

    if (autoPrintNewJobs) {
      void handlePrintJob(job);
    }
  };"""

if old in text:
    text = text.replace(old, new, 1)
elif "if (autoPrintNewJobs)" not in text:
    raise SystemExit("Could not find handleCreatePrintJob block.")

# 3. Add badge.
if "{autoPrintNewJobs ? 'Auto Print ON' : 'Auto Print OFF'}" not in text:
    marker = """          <span className="rounded-full bg-purple-600 px-3 py-1 text-xs font-black text-white">
            {silentPrint ? 'Silent Print' : 'Print Dialog'}
          </span>"""

    replacement = marker + """

          <span
            className={`rounded-full px-3 py-1 text-xs font-black text-white ${
              autoPrintNewJobs ? 'bg-emerald-600' : 'bg-slate-500'
            }`}
          >
            {autoPrintNewJobs ? 'Auto Print ON' : 'Auto Print OFF'}
          </span>"""

    if marker not in text:
        raise SystemExit("Could not find print mode badge marker.")

    text = text.replace(marker, replacement, 1)

# 4. Add UI toggle after print mode block.
if "Auto-print new jobs" not in text:
    marker = """          <p className="mt-3 text-xs font-bold text-slate-500">
            {silentPrint
              ? 'Silent print akan langsung kirim ke selected/default printer tanpa dialog.'
              : 'Print dialog akan muncul dulu sebelum user konfirmasi print.'}
          </p>
        </div>
      </div>"""

    replacement = """          <p className="mt-3 text-xs font-bold text-slate-500">
            {silentPrint
              ? 'Silent print akan langsung kirim ke selected/default printer tanpa dialog.'
              : 'Print dialog akan muncul dulu sebelum user konfirmasi print.'}
          </p>
        </div>

        <div className="mt-4 rounded-2xl border border-emerald-100 bg-emerald-50 p-3">
          <label className="flex items-center gap-3 rounded-2xl bg-white px-4 py-3">
            <input
              type="checkbox"
              checked={autoPrintNewJobs}
              onChange={(event) => setAutoPrintNewJobs(event.target.checked)}
            />
            <span className="text-sm font-black text-emerald-900">
              Auto-print new jobs
            </span>
          </label>

          <p className="mt-3 text-xs font-bold text-emerald-700">
            Kalau aktif, tombol Create Job akan langsung mengirim job ke Print
            Bridge tanpa perlu klik Print via Bridge lagi.
          </p>
        </div>
      </div>"""

    if marker not in text:
        raise SystemExit("Could not find print mode block marker.")

    text = text.replace(marker, replacement, 1)

# 5. Update button label.
text = text.replace(
    ">Create Job</button>",
    ">{autoPrintNewJobs ? 'Create & Auto Print' : 'Create Job'}</button>",
    1,
)

path.write_text(text)
print("PATCH:", path)
PY

echo ""
echo "Relevant lines:"
grep -n "autoPrintNewJobs\\|Auto-print new jobs\\|Create & Auto Print\\|Auto Print" "$PANEL" || true

echo ""
echo "9A3V done."
