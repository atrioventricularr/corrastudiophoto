import React from 'react';
import { useLayouts } from '../../layouts';
import { createPaperSnapshotFromLayout, createPhotoTemplate, useTemplates } from '../../templates';

export function TemplateAdminPanel() {
  const {
    templates,
    activeTemplateId,
    activeTemplate,
    setActiveTemplateId,
    setTemplateStatus,
    resetTemplates,
    addTemplate,
  } = useTemplates();

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

      <div className="mt-5 rounded-3xl border border-slate-200 bg-slate-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
          Template Actions
        </p>

        <div className="mt-4 grid gap-3 sm:grid-cols-5">
          <button
            type="button"
            onClick={handleCreateTemplateFromActiveLayout}
            className="rounded-2xl bg-slate-950 px-4 py-3 text-xs font-black text-white"
          >
            Create From Layout
          </button>

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
