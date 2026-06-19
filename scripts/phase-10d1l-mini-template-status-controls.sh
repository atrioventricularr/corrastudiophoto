#!/usr/bin/env bash
set -euo pipefail

FILE="apps/booth-ui/src/components/admin/TemplateAdminPanel.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: TemplateAdminPanel.tsx not found. Run 10D1K mini first."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/admin/TemplateAdminPanel.tsx")
text = path.read_text()

old = """    activeTemplate,
    setActiveTemplateId,
  } = useTemplates();"""

new = """    activeTemplate,
    setActiveTemplateId,
    setTemplateStatus,
    resetTemplates,
  } = useTemplates();"""

if old in text and "setTemplateStatus" not in text.split("} = useTemplates();", 1)[0]:
    text = text.replace(old, new, 1)

marker = """      <div className="mt-5 rounded-3xl border border-dashed border-slate-300 bg-slate-50 p-5 text-center">"""

block = """      <div className="mt-5 rounded-3xl border border-slate-200 bg-slate-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
          Template Actions
        </p>

        <div className="mt-4 grid gap-3 sm:grid-cols-4">
          <button
            type="button"
            onClick={() => setTemplateStatus(activeTemplate.id, 'draft')}
            className="rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-xs font-black text-amber-700"
          >
            Set Draft
          </button>

          <button
            type="button"
            onClick={() => setTemplateStatus(activeTemplate.id, 'active')}
            className="rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-xs font-black text-emerald-700"
          >
            Set Active
          </button>

          <button
            type="button"
            onClick={() => setTemplateStatus(activeTemplate.id, 'archived')}
            className="rounded-2xl border border-slate-200 bg-white px-4 py-3 text-xs font-black text-slate-600"
          >
            Archive
          </button>

          <button
            type="button"
            onClick={() => {
              if (window.confirm('Reset all templates to default?')) {
                resetTemplates();
              }
            }}
            className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-xs font-black text-red-700"
          >
            Reset
          </button>
        </div>
      </div>

"""

if "Template Actions" not in text:
    if marker not in text:
        raise SystemExit("Could not find placeholder marker.")
    text = text.replace(marker, block + marker, 1)

path.write_text(text)
print("PATCH file:", path)
PY

echo "10D1L mini done."
