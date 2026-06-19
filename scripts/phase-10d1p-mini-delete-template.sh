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

old = """    addTemplate,
    updateTemplate,
  } = useTemplates();"""

new = """    addTemplate,
    updateTemplate,
    removeTemplate,
  } = useTemplates();"""

if old in text and "removeTemplate" not in text.split("} = useTemplates();", 1)[0]:
    text = text.replace(old, new, 1)

text = text.replace(
    'className="mt-4 grid gap-3 sm:grid-cols-6"',
    'className="mt-4 grid gap-3 sm:grid-cols-7"',
)

marker = """          <button
            type="button"
            onClick={() => {
              if (window.confirm('Reset all templates to default?')) {
                resetTemplates();
              }
            }}
            className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-xs font-black text-red-700"
          >
            Reset
          </button>"""

button = """          <button
            type="button"
            onClick={() => {
              if (window.confirm(`Delete template "${activeTemplate.name}"?`)) {
                removeTemplate(activeTemplate.id);
              }
            }}
            className="rounded-2xl border border-red-200 bg-white px-4 py-3 text-xs font-black text-red-700"
          >
            Delete
          </button>

"""

if "removeTemplate(activeTemplate.id)" not in text:
    if marker not in text:
        raise SystemExit("Could not find Reset button marker.")
    text = text.replace(marker, button + marker, 1)

path.write_text(text)
print("PATCH file:", path)
PY

echo "10D1P mini done."
