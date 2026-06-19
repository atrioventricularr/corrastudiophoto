#!/usr/bin/env bash
set -euo pipefail

FILE="apps/booth-ui/src/components/admin/TemplateAdminPanel.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: TemplateAdminPanel.tsx not found."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/admin/TemplateAdminPanel.tsx")
text = path.read_text()

old = """    resetTemplates,
    addTemplate,
  } = useTemplates();"""

new = """    resetTemplates,
    addTemplate,
    updateTemplate,
  } = useTemplates();"""

if old in text and "updateTemplate" not in text.split("} = useTemplates();", 1)[0]:
    text = text.replace(old, new, 1)

marker = """      <div className="mt-5 grid gap-4 lg:grid-cols-3">"""

block = """      <div className="mt-5 rounded-3xl border border-slate-200 bg-slate-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
          Template Details
        </p>

        <div className="mt-4 grid gap-4 lg:grid-cols-2">
          <label className="block">
            <span className="text-xs font-black uppercase tracking-wider text-slate-400">
              Template Name
            </span>
            <input
              value={activeTemplate.name}
              onChange={(event) =>
                updateTemplate(activeTemplate.id, {
                  name: event.target.value,
                })
              }
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none"
            />
          </label>

          <label className="block">
            <span className="text-xs font-black uppercase tracking-wider text-slate-400">
              Customer-Facing Name
            </span>
            <input
              value={activeTemplate.customerFacingName}
              onChange={(event) =>
                updateTemplate(activeTemplate.id, {
                  customerFacingName: event.target.value,
                })
              }
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none"
            />
          </label>
        </div>

        <label className="mt-4 block">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Notes
          </span>
          <textarea
            value={activeTemplate.notes || ''}
            onChange={(event) =>
              updateTemplate(activeTemplate.id, {
                notes: event.target.value,
              })
            }
            rows={3}
            className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none"
          />
        </label>
      </div>

"""

if "Template Details" not in text:
    if marker not in text:
        raise SystemExit("Could not find template info grid marker.")
    text = text.replace(marker, block + marker, 1)

path.write_text(text)
print("PATCH file:", path)
PY

echo "10D1O mini done."
