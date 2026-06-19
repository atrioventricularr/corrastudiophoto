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

# 1. Add history type
if "type RenderHistoryItem" not in text:
    text = text.replace(
        "type RenderOutputKind = 'template-preview' | 'calibration-sheet';",
        """type RenderOutputKind = 'template-preview' | 'calibration-sheet';

type RenderHistoryItem = {
  id: string;
  kind: RenderOutputKind;
  mode: RenderMode;
  label: string;
  size: string;
  createdAt: string;
};""",
    )

# 2. Add state
if "renderHistory" not in text:
    text = text.replace(
        """  const [renderOutputKind, setRenderOutputKind] =
    useState<RenderOutputKind>('template-preview');""",
        """  const [renderOutputKind, setRenderOutputKind] =
    useState<RenderOutputKind>('template-preview');
  const [renderHistory, setRenderHistory] = useState<RenderHistoryItem[]>([]);""",
    )

# 3. Add helper before return
marker = """  const handleDownloadRenderMetadata = () => {"""

helper = """  const addRenderHistory = (item: Omit<RenderHistoryItem, 'id' | 'createdAt'>) => {
    setRenderHistory((current) => [
      {
        ...item,
        id: `render-${Date.now()}-${Math.random().toString(16).slice(2)}`,
        createdAt: new Date().toLocaleString(),
      },
      ...current,
    ].slice(0, 10));
  };

"""

if "addRenderHistory" not in text:
    if marker not in text:
        raise SystemExit("Could not find metadata handler marker.")
    text = text.replace(marker, helper + marker, 1)

# 4. Add history update after normal render preview
old = """      setRenderOutputKind('template-preview');
      setPreviewUrl(result.dataUrl);
      setRenderInfo("""

new = """      setRenderOutputKind('template-preview');
      setPreviewUrl(result.dataUrl);
      addRenderHistory({
        kind: 'template-preview',
        mode: renderMode,
        label: activeTemplate.name,
        size: `${result.widthPx} × ${result.heightPx}px`,
      });
      setRenderInfo("""

if "kind: 'template-preview'," not in text:
    if old not in text:
        raise SystemExit("Could not find template preview render block.")
    text = text.replace(old, new, 1)

# 5. Add history update after calibration render
old = """    setRenderOutputKind('calibration-sheet');
    setPreviewUrl(result.dataUrl);
    setRenderInfo(`${result.widthPx} × ${result.heightPx}px calibration sheet PNG`);"""

new = """    setRenderOutputKind('calibration-sheet');
    setPreviewUrl(result.dataUrl);
    addRenderHistory({
      kind: 'calibration-sheet',
      mode: renderMode,
      label: printerProfile.printerModel,
      size: `${result.widthPx} × ${result.heightPx}px`,
    });
    setRenderInfo(`${result.widthPx} × ${result.heightPx}px calibration sheet PNG`);"""

if "kind: 'calibration-sheet'," not in text:
    if old not in text:
        raise SystemExit("Could not find calibration render block.")
    text = text.replace(old, new, 1)

# 6. Insert UI before preview image block
marker = """      {previewUrl && ("""

history_block = """      <div className="mt-4 rounded-2xl border border-slate-200 bg-white p-4">
        <div className="flex items-center justify-between gap-3">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
              Render History
            </p>
            <p className="mt-1 text-xs font-bold text-slate-500">
              10 hasil render terakhir di sesi admin ini.
            </p>
          </div>

          <button
            type="button"
            onClick={() => setRenderHistory([])}
            disabled={renderHistory.length === 0}
            className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-2 text-xs font-black text-slate-600 disabled:opacity-40"
          >
            Clear History
          </button>
        </div>

        <div className="mt-3 space-y-2">
          {renderHistory.length === 0 && (
            <div className="rounded-2xl bg-slate-50 p-3 text-center text-xs font-bold text-slate-400">
              No render history yet.
            </div>
          )}

          {renderHistory.map((item) => (
            <div
              key={item.id}
              className="grid gap-2 rounded-2xl bg-slate-50 p-3 text-xs sm:grid-cols-[130px_120px_1fr_140px]"
            >
              <div className="font-black text-slate-700">
                {item.kind === 'calibration-sheet'
                  ? 'Calibration'
                  : 'Template'}
              </div>

              <div className="font-black text-slate-500">
                {item.mode === 'print-ready' ? 'Print-Ready' : 'Raw'}
              </div>

              <div className="truncate font-bold text-slate-600">
                {item.label} · {item.size}
              </div>

              <div className="font-mono text-[10px] font-bold text-slate-400">
                {item.createdAt}
              </div>
            </div>
          ))}
        </div>
      </div>

"""

if "Render History" not in text:
    if marker not in text:
        raise SystemExit("Could not find preview block marker.")
    text = text.replace(marker, history_block + marker, 1)

path.write_text(text)
print("10D2M patched:", path)
PY

echo "10D2M mini done."
