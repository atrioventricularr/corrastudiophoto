#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 10D1G - Layout Actions"
echo "========================================"

mkdir -p apps/booth-ui/src/components/admin

cat > apps/booth-ui/src/components/admin/LayoutActionsPanel.tsx <<'TSX'
import React from 'react';
import {
  createLayoutSlot,
  createPhotoLayout,
  useLayouts,
  type PhotoLayout,
} from '../../layouts';

function createId(prefix: string): string {
  const random =
    typeof crypto !== 'undefined' && 'randomUUID' in crypto
      ? crypto.randomUUID()
      : `${Date.now()}-${Math.random().toString(16).slice(2)}`;

  return `${prefix}-${random}`;
}

function duplicateLayout(layout: PhotoLayout): PhotoLayout {
  const now = new Date().toISOString();
  const layoutId = createId('custom-layout');

  return {
    ...layout,
    id: layoutId,
    name: `${layout.name} Copy`,
    mode: 'custom',
    slots: layout.slots.map((slot) => ({
      ...slot,
      id: `${slot.id}-${layoutId}`,
    })),
    notes: `Duplicated from ${layout.name}.`,
    createdAt: now,
    updatedAt: now,
  };
}

export function LayoutActionsPanel() {
  const {
    activeLayout,
    addLayout,
    resetLayouts,
  } = useLayouts();

  const handleDuplicateLayout = () => {
    addLayout(duplicateLayout(activeLayout));
  };

  const handleCreateBlankLayout = () => {
    const layoutId = createId('blank-layout');

    addLayout(
      createPhotoLayout({
        id: layoutId,
        name: 'Blank Custom 4R Layout',
        mode: 'custom',
        paperPresetId: '4r',
        orientation: 'portrait',
        slots: [
          createLayoutSlot({
            id: `${layoutId}-slot-1`,
            name: 'Photo 1',
            captureOrder: 1,
            xPercent: 10,
            yPercent: 10,
            widthPercent: 80,
            heightPercent: 80,
            shape: 'rectangle',
            guideLabel: 'Pose 1',
          }),
        ],
        notes: 'Blank custom layout created from admin.',
      }),
    );
  };

  return (
    <section className="rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
      <div>
        <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
          Layout Actions
        </p>
        <h4 className="mt-1 text-xl font-black text-slate-950">
          Duplicate / Create / Reset
        </h4>
        <p className="mt-1 text-sm font-semibold text-slate-500">
          Pakai duplicate supaya preset bawaan tidak rusak saat bikin custom layout.
        </p>
      </div>

      <div className="mt-5 grid gap-3 sm:grid-cols-3">
        <button
          type="button"
          onClick={handleDuplicateLayout}
          className="rounded-2xl bg-slate-950 px-5 py-4 text-sm font-black text-white"
        >
          Duplicate Active Layout
        </button>

        <button
          type="button"
          onClick={handleCreateBlankLayout}
          className="rounded-2xl border border-slate-200 bg-slate-50 px-5 py-4 text-sm font-black text-slate-700"
        >
          Create Blank 4R
        </button>

        <button
          type="button"
          onClick={resetLayouts}
          className="rounded-2xl border border-red-200 bg-red-50 px-5 py-4 text-sm font-black text-red-700"
        >
          Reset Layouts
        </button>
      </div>
    </section>
  );
}
TSX

FILE="apps/booth-ui/src/components/admin/LayoutAdminPanel.tsx"

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/admin/LayoutAdminPanel.tsx")
text = path.read_text()

if "LayoutActionsPanel" not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(
        insert_at,
        "import { LayoutActionsPanel } from './LayoutActionsPanel';",
    )
    text = "\n".join(lines) + "\n"

marker = """      <div className="mt-5 grid gap-4 lg:grid-cols-4">"""

insert = """      <div className="mt-5">
        <LayoutActionsPanel />
      </div>

"""

if "<LayoutActionsPanel />" not in text:
    if marker not in text:
        raise SystemExit("Could not find layout info grid marker.")
    text = text.replace(marker, insert + marker, 1)

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Created:"
echo "- apps/booth-ui/src/components/admin/LayoutActionsPanel.tsx"
echo ""
echo "Patched:"
echo "- apps/booth-ui/src/components/admin/LayoutAdminPanel.tsx"
echo ""
echo "Phase 10D1G completed."
