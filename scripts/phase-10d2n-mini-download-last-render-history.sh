#!/usr/bin/env bash
set -euo pipefail

FILE="apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: TemplateRenderPreviewPanel.tsx not found."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx")
text = path.read_text()

# 1. Add dataUrl to render history item type
if "dataUrl: string;" not in text:
    text = text.replace(
        """  label: string;
  size: string;
  createdAt: string;""",
        """  label: string;
  size: string;
  dataUrl: string;
  createdAt: string;""",
        1,
    )

# 2. Store dataUrl in template preview history
if "dataUrl: result.dataUrl," not in text:
    text = text.replace(
        """        label: activeTemplate.name,
        size: `${result.widthPx} × ${result.heightPx}px`,""",
        """        label: activeTemplate.name,
        size: `${result.widthPx} × ${result.heightPx}px`,
        dataUrl: result.dataUrl,""",
        1,
    )

# 3. Store dataUrl in calibration history
if text.count("dataUrl: result.dataUrl,") < 2:
    text = text.replace(
        """      label: printerProfile.printerModel,
      size: `${result.widthPx} × ${result.heightPx}px`,""",
        """      label: printerProfile.printerModel,
      size: `${result.widthPx} × ${result.heightPx}px`,
      dataUrl: result.dataUrl,""",
        1,
    )

# 4. Add download history helper
marker = """  const handleDownloadRenderMetadata = () => {"""

helper = """  const handleDownloadHistoryItem = (item: RenderHistoryItem) => {
    const safeLabel = item.label
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');

    const link = document.createElement('a');
    link.href = item.dataUrl;
    link.download = `${safeLabel || 'corra-render'}-${item.mode}-${item.kind}.png`;
    document.body.appendChild(link);
    link.click();
    link.remove();
  };

  const handleDownloadLatestRender = () => {
    const latest = renderHistory[0];

    if (!latest) return;

    handleDownloadHistoryItem(latest);
  };

"""

if "handleDownloadLatestRender" not in text:
    if marker not in text:
        raise SystemExit("Could not find metadata handler marker.")
    text = text.replace(marker, helper + marker, 1)

# 5. Add Download Latest button in history header
old = """          <button
            type="button"
            onClick={() => setRenderHistory([])}
            disabled={renderHistory.length === 0}
            className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-2 text-xs font-black text-slate-600 disabled:opacity-40"
          >
            Clear History
          </button>"""

new = """          <div className="flex gap-2">
            <button
              type="button"
              onClick={handleDownloadLatestRender}
              disabled={renderHistory.length === 0}
              className="rounded-2xl bg-slate-950 px-4 py-2 text-xs font-black text-white disabled:opacity-40"
            >
              Download Latest
            </button>

            <button
              type="button"
              onClick={() => setRenderHistory([])}
              disabled={renderHistory.length === 0}
              className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-2 text-xs font-black text-slate-600 disabled:opacity-40"
            >
              Clear History
            </button>
          </div>"""

if "Download Latest" not in text:
    if old not in text:
        raise SystemExit("Could not find Clear History button.")
    text = text.replace(old, new, 1)

# 6. Add per-row download button
text = text.replace(
    """className="grid gap-2 rounded-2xl bg-slate-50 p-3 text-xs sm:grid-cols-[130px_120px_1fr_140px]\"""",
    """className="grid gap-2 rounded-2xl bg-slate-50 p-3 text-xs sm:grid-cols-[130px_120px_1fr_140px_90px]\"""",
)

old_row_end = """              <div className="font-mono text-[10px] font-bold text-slate-400">
                {item.createdAt}
              </div>
            </div>"""

new_row_end = """              <div className="font-mono text-[10px] font-bold text-slate-400">
                {item.createdAt}
              </div>

              <button
                type="button"
                onClick={() => handleDownloadHistoryItem(item)}
                className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-[10px] font-black text-slate-700"
              >
                Download
              </button>
            </div>"""

if "handleDownloadHistoryItem(item)" not in text:
    if old_row_end not in text:
        raise SystemExit("Could not find render history row end.")
    text = text.replace(old_row_end, new_row_end, 1)

path.write_text(text)
print("10D2N patched:", path)
PY

echo "10D2N mini done."
