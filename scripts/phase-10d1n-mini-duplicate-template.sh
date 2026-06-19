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

marker = """  const handleCreateTemplateFromActiveLayout = () => {
    const template = createPhotoTemplate({
      name: `${activeLayout.name} Template`,
      customerFacingName: activeLayout.name,
      layoutId: activeLayout.id,
      layoutName: activeLayout.name,
      paperSnapshot: createPaperSnapshotFromLayout(activeLayout),
      tags: ['custom', activeLayout.paperPresetId],
      notes: 'Created from active layout in admin.',
    });

    addTemplate(template);
  };

  return ("""

insert = """  const handleCreateTemplateFromActiveLayout = () => {
    const template = createPhotoTemplate({
      name: `${activeLayout.name} Template`,
      customerFacingName: activeLayout.name,
      layoutId: activeLayout.id,
      layoutName: activeLayout.name,
      paperSnapshot: createPaperSnapshotFromLayout(activeLayout),
      tags: ['custom', activeLayout.paperPresetId],
      notes: 'Created from active layout in admin.',
    });

    addTemplate(template);
  };

  const handleDuplicateActiveTemplate = () => {
    const now = new Date().toISOString();

    addTemplate({
      ...activeTemplate,
      id: `template-copy-${Date.now()}`,
      name: `${activeTemplate.name} Copy`,
      customerFacingName: `${activeTemplate.customerFacingName} Copy`,
      status: 'draft',
      notes: `Duplicated from ${activeTemplate.name}.`,
      createdAt: now,
      updatedAt: now,
    });
  };

  return ("""

if "handleDuplicateActiveTemplate" not in text:
    if marker not in text:
        raise SystemExit("Could not find create template handler block.")
    text = text.replace(marker, insert, 1)

text = text.replace(
    'className="mt-4 grid gap-3 sm:grid-cols-5"',
    'className="mt-4 grid gap-3 sm:grid-cols-6"',
)

button_marker = """          <button
            type="button"
            onClick={() => setTemplateStatus(activeTemplate.id, 'draft')}"""

button = """          <button
            type="button"
            onClick={handleDuplicateActiveTemplate}
            className="rounded-2xl border border-blue-200 bg-blue-50 px-4 py-3 text-xs font-black text-blue-700"
          >
            Duplicate
          </button>

"""

if "onClick={handleDuplicateActiveTemplate}" not in text:
    if button_marker not in text:
        raise SystemExit("Could not find Set Draft button marker.")
    text = text.replace(button_marker, button + button_marker, 1)

path.write_text(text)
print("PATCH file:", path)
PY

echo "10D1N mini done."
