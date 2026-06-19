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

# Add sync handler before duplicate handler.
marker = """  const handleDuplicateActiveTemplate = () => {"""

handler = """  const handleSyncTemplateFromActiveLayout = () => {
    updateTemplate(activeTemplate.id, {
      layoutId: activeLayout.id,
      layoutName: activeLayout.name,
      paperSnapshot: createPaperSnapshotFromLayout(activeLayout),
      status: 'draft',
      notes: `Synced from active layout: ${activeLayout.name}.`,
    });
  };

"""

if "handleSyncTemplateFromActiveLayout" not in text:
    if marker not in text:
        raise SystemExit("Could not find duplicate handler marker.")
    text = text.replace(marker, handler + marker, 1)

# Make action grid wider if previous class exists.
text = text.replace(
    'className="mt-4 grid gap-3 sm:grid-cols-7"',
    'className="mt-4 grid gap-3 sm:grid-cols-8"',
)

text = text.replace(
    'className="mt-4 grid gap-3 sm:grid-cols-6"',
    'className="mt-4 grid gap-3 sm:grid-cols-8"',
)

# Insert sync button after Create From Layout button.
button_marker = """          <button
            type="button"
            onClick={handleDuplicateActiveTemplate}"""

sync_button = """          <button
            type="button"
            onClick={handleSyncTemplateFromActiveLayout}
            className="rounded-2xl border border-indigo-200 bg-indigo-50 px-4 py-3 text-xs font-black text-indigo-700"
          >
            Sync Layout
          </button>

"""

if "onClick={handleSyncTemplateFromActiveLayout}" not in text:
    if button_marker not in text:
        raise SystemExit("Could not find Duplicate button marker.")
    text = text.replace(button_marker, sync_button + button_marker, 1)

path.write_text(text)
print("PATCH:", path)
PY

echo "10D1X mini done."
