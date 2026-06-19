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

# Imports
if "useLayouts" not in text:
    text = text.replace(
        "import React from 'react';",
        "import React from 'react';\nimport { useLayouts } from '../../layouts';",
    )

text = text.replace(
    "import { useTemplates } from '../../templates';",
    "import { createPaperSnapshotFromLayout, createPhotoTemplate, useTemplates } from '../../templates';",
)

# Add addTemplate to useTemplates destructuring
old = """    setTemplateStatus,
    resetTemplates,
  } = useTemplates();"""

new = """    setTemplateStatus,
    resetTemplates,
    addTemplate,
  } = useTemplates();"""

if old in text and "addTemplate" not in text.split("} = useTemplates();", 1)[0]:
    text = text.replace(old, new, 1)

# Add activeLayout + handler
marker = """  } = useTemplates();

  return ("""

insert = """  } = useTemplates();

  const { activeLayout } = useLayouts();

  const handleCreateTemplateFromActiveLayout = () => {
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

if "handleCreateTemplateFromActiveLayout" not in text:
    if marker not in text:
        raise SystemExit("Could not find useTemplates return marker.")
    text = text.replace(marker, insert, 1)

# Make grid 5 cols
text = text.replace(
    'className="mt-4 grid gap-3 sm:grid-cols-4"',
    'className="mt-4 grid gap-3 sm:grid-cols-5"',
)

# Insert create button before Set Draft
button_marker = """          <button
            type="button"
            onClick={() => setTemplateStatus(activeTemplate.id, 'draft')}"""

button = """          <button
            type="button"
            onClick={handleCreateTemplateFromActiveLayout}
            className="rounded-2xl bg-slate-950 px-4 py-3 text-xs font-black text-white"
          >
            Create From Layout
          </button>

"""

if "Create From Layout" not in text:
    if button_marker not in text:
        raise SystemExit("Could not find first action button marker.")
    text = text.replace(button_marker, button + button_marker, 1)

path.write_text(text)
print("PATCH file:", path)
PY

echo "10D1M mini done."
