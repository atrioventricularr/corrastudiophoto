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

text = text.replace(
    "import { renderPrintReadyTemplateToCanvas } from '../../render';",
    "import { renderFinalTemplateToCanvas, renderPrintReadyTemplateToCanvas } from '../../render';",
)

if "type RenderMode" not in text:
    text = text.replace(
        "import { useTemplates } from '../../templates';",
        "import { useTemplates } from '../../templates';\n\ntype RenderMode = 'raw' | 'print-ready';",
    )

if "const [renderMode" not in text:
    text = text.replace(
        "  const [isRendering, setIsRendering] = useState(false);",
        "  const [isRendering, setIsRendering] = useState(false);\n  const [renderMode, setRenderMode] = useState<RenderMode>('print-ready');",
    )

old_render = """      const result = await renderPrintReadyTemplateToCanvas({
        template: activeTemplate,
        layout,
        printerProfile,
        showEmptySlotPlaceholder: true,
      });

      setPreviewUrl(result.dataUrl);
      setRenderInfo(`${result.widthPx} × ${result.heightPx}px print-ready PNG`);"""

new_render = """      const result =
        renderMode === 'print-ready'
          ? await renderPrintReadyTemplateToCanvas({
              template: activeTemplate,
              layout,
              printerProfile,
              showEmptySlotPlaceholder: true,
            })
          : await renderFinalTemplateToCanvas({
              template: activeTemplate,
              layout,
              showEmptySlotPlaceholder: true,
            });

      setPreviewUrl(result.dataUrl);
      setRenderInfo(
        `${result.widthPx} × ${result.heightPx}px ${
          renderMode === 'print-ready' ? 'print-ready' : 'raw template'
        } PNG`,
      );"""

if old_render in text:
    text = text.replace(old_render, new_render, 1)

old_desc = "Tes output final print-ready dengan placeholder slot foto dan printer profile aktif."
new_desc = "Bandingkan raw template render vs print-ready render dengan printer profile aktif."
text = text.replace(old_desc, new_desc)

marker = """      <div className="mt-4 rounded-2xl border border-indigo-100 bg-indigo-50 p-4">"""

toggle = """      <div className="mt-4 rounded-2xl border border-slate-200 bg-slate-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
          Render Mode
        </p>

        <div className="mt-3 grid gap-3 sm:grid-cols-2">
          <button
            type="button"
            onClick={() => setRenderMode('raw')}
            className={`rounded-2xl px-4 py-3 text-xs font-black ${
              renderMode === 'raw'
                ? 'bg-slate-950 text-white'
                : 'border border-slate-200 bg-white text-slate-700'
            }`}
          >
            Raw Template
          </button>

          <button
            type="button"
            onClick={() => setRenderMode('print-ready')}
            className={`rounded-2xl px-4 py-3 text-xs font-black ${
              renderMode === 'print-ready'
                ? 'bg-slate-950 text-white'
                : 'border border-slate-200 bg-white text-slate-700'
            }`}
          >
            Print-Ready
          </button>
        </div>
      </div>

"""

if "Render Mode" not in text:
    if marker not in text:
        raise SystemExit("Could not find printer profile info marker.")
    text = text.replace(marker, toggle + marker, 1)

path.write_text(text)
print("PATCH:", path)
PY

echo "10D2E mini done."
