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
