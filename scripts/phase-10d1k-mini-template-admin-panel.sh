#!/usr/bin/env bash
set -euo pipefail

mkdir -p apps/booth-ui/src/components/admin

cat > apps/booth-ui/src/components/admin/TemplateAdminPanel.tsx <<'TSX'
import React from 'react';
import { useTemplates } from '../../templates';

export function TemplateAdminPanel() {
  const {
    templates,
    activeTemplateId,
    activeTemplate,
    setActiveTemplateId,
  } = useTemplates();

  return (
    <section className="rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Template
          </p>
          <h3 className="mt-1 text-2xl font-black text-slate-950">
            Template Manager
          </h3>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Basic template manager untuk frame PNG, layout, paper, dan print output.
          </p>
        </div>

        <span className="rounded-full bg-slate-950 px-3 py-1 text-xs font-black uppercase text-white">
          {activeTemplate.status}
        </span>
      </div>

      <label className="mt-5 block">
        <span className="text-xs font-black uppercase tracking-wider text-slate-400">
          Active Template
        </span>
        <select
          value={activeTemplateId}
          onChange={(event) => setActiveTemplateId(event.target.value)}
          className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
        >
          {templates.map((template) => (
            <option key={template.id} value={template.id}>
              {template.name}
            </option>
          ))}
        </select>
      </label>

      <div className="mt-5 grid gap-4 lg:grid-cols-3">
        <div className="rounded-3xl bg-slate-50 p-4">
          <p className="text-xs font-black uppercase text-slate-400">
            Layout
          </p>
          <p className="mt-2 text-lg font-black text-slate-950">
            {activeTemplate.layoutName}
          </p>
          <p className="mt-1 font-mono text-xs font-bold text-slate-500">
            {activeTemplate.layoutId}
          </p>
        </div>

        <div className="rounded-3xl bg-slate-50 p-4">
          <p className="text-xs font-black uppercase text-slate-400">
            Paper
          </p>
          <p className="mt-2 text-lg font-black text-slate-950">
            {activeTemplate.paperSnapshot.paperName}
          </p>
          <p className="mt-1 text-xs font-bold text-slate-500">
            {activeTemplate.paperSnapshot.paperWidthInch} ×{' '}
            {activeTemplate.paperSnapshot.paperHeightInch} inch
          </p>
        </div>

        <div className="rounded-3xl bg-slate-50 p-4">
          <p className="text-xs font-black uppercase text-slate-400">
            Canvas
          </p>
          <p className="mt-2 text-lg font-black text-slate-950">
            {activeTemplate.paperSnapshot.canvasWidthPx} ×{' '}
            {activeTemplate.paperSnapshot.canvasHeightPx}
          </p>
          <p className="mt-1 text-xs font-bold text-slate-500">
            {activeTemplate.paperSnapshot.orientation} ·{' '}
            {activeTemplate.paperSnapshot.dpi} DPI
          </p>
        </div>
      </div>

      <div className="mt-5 rounded-3xl border border-dashed border-slate-300 bg-slate-50 p-5 text-center">
        <p className="text-sm font-black text-slate-700">
          Frame PNG upload belum dipasang.
        </p>
        <p className="mt-1 text-xs font-semibold text-slate-500">
          Next phase baru kita tambah upload frame overlay + layer template.
        </p>
      </div>
    </section>
  );
}
TSX

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/components/AdminPanel.tsx")
text = path.read_text()

if "TemplateAdminPanel" not in text:
    lines = text.splitlines()
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = i + 1
    lines.insert(insert_at, "import { TemplateAdminPanel } from './admin/TemplateAdminPanel';")
    text = "\n".join(lines) + "\n"

text = re.sub(
    r'<AdminPage activeSection=\{activeSection\} section="template">[\s\S]*?</AdminPage>',
    '''<AdminPage activeSection={activeSection} section="template">
          <TemplateAdminPanel />
        </AdminPage>''',
    text,
    count=1,
)

path.write_text(text)
PY

echo "10D1K mini done."
