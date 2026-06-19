#!/usr/bin/env bash
set -euo pipefail

mkdir -p apps/booth-ui/src/components/admin

cat > apps/booth-ui/src/components/admin/TemplateAssetSummaryPanel.tsx <<'TSX'
import React from 'react';
import { useTemplates } from '../../templates';

export function TemplateAssetSummaryPanel() {
  const { activeTemplate } = useTemplates();

  const hasFrame = Boolean(activeTemplate.frameOverlayAssetId);
  const hasBackground = Boolean(activeTemplate.backgroundAssetId);
  const visibleLayers = activeTemplate.layers.filter((layer) => layer.visible);

  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-4">
      <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
        Asset Summary
      </p>

      <div className="mt-4 grid gap-3 sm:grid-cols-5">
        <div className="rounded-2xl bg-slate-50 p-3">
          <p className="text-[10px] font-black uppercase text-slate-400">
            Assets
          </p>
          <p className="mt-1 text-xl font-black text-slate-950">
            {activeTemplate.assets.length}
          </p>
        </div>

        <div className="rounded-2xl bg-slate-50 p-3">
          <p className="text-[10px] font-black uppercase text-slate-400">
            Layers
          </p>
          <p className="mt-1 text-xl font-black text-slate-950">
            {activeTemplate.layers.length}
          </p>
        </div>

        <div className="rounded-2xl bg-slate-50 p-3">
          <p className="text-[10px] font-black uppercase text-slate-400">
            Visible
          </p>
          <p className="mt-1 text-xl font-black text-slate-950">
            {visibleLayers.length}
          </p>
        </div>

        <div className="rounded-2xl bg-blue-50 p-3">
          <p className="text-[10px] font-black uppercase text-blue-400">
            Frame
          </p>
          <p className="mt-1 text-sm font-black text-blue-900">
            {hasFrame ? 'Ready' : 'Missing'}
          </p>
        </div>

        <div className="rounded-2xl bg-purple-50 p-3">
          <p className="text-[10px] font-black uppercase text-purple-400">
            Background
          </p>
          <p className="mt-1 text-sm font-black text-purple-900">
            {hasBackground ? 'Ready' : 'Missing'}
          </p>
        </div>
      </div>
    </section>
  );
}
TSX

FILE="apps/booth-ui/src/components/admin/TemplateAdminPanel.tsx"

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/admin/TemplateAdminPanel.tsx")
text = path.read_text()

if "TemplateAssetSummaryPanel" not in text:
    text = text.replace(
        "import { TemplateLayerListPanel } from './TemplateLayerListPanel';",
        "import { TemplateLayerListPanel } from './TemplateLayerListPanel';\nimport { TemplateAssetSummaryPanel } from './TemplateAssetSummaryPanel';",
    )

preview_block = """      <div className="mt-5">
        <TemplatePreviewCanvas template={activeTemplate} />
      </div>"""

summary_block = """      <div className="mt-5">
        <TemplateAssetSummaryPanel />
      </div>"""

if "<TemplateAssetSummaryPanel />" not in text:
    if preview_block in text:
        text = text.replace(preview_block, preview_block + "\n\n" + summary_block, 1)
    else:
        raise SystemExit("Could not find TemplatePreviewCanvas block.")

path.write_text(text)
print("PATCH:", path)
PY

echo "10D1Y mini done."
