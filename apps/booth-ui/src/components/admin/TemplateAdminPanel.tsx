import React from 'react';
import { useLayouts } from '../../layouts';
import { TemplatePreviewCanvas } from '../templates';
import { TemplateLayerListPanel } from './TemplateLayerListPanel';
import { TemplateAssetSummaryPanel } from './TemplateAssetSummaryPanel';
import { createPaperSnapshotFromLayout, createPhotoTemplate, createTemplateAsset, createTemplateLayer, useTemplates } from '../../templates';

export function TemplateAdminPanel() {
  const {
    templates,
    activeTemplateId,
    activeTemplate,
    setActiveTemplateId,
    setTemplateStatus,
    resetTemplates,
    addTemplate,
    updateTemplate,
    removeTemplate,
    addTemplateAsset,
    addTemplateLayer,
    removeTemplateAsset,
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

  const handleSyncTemplateFromActiveLayout = () => {
    updateTemplate(activeTemplate.id, {
      layoutId: activeLayout.id,
      layoutName: activeLayout.name,
      paperSnapshot: createPaperSnapshotFromLayout(activeLayout),
      status: 'draft',
      notes: `Synced from active layout: ${activeLayout.name}.`,
    });
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

  const frameOverlayAsset = activeTemplate.assets.find(
    (asset) => asset.id === activeTemplate.frameOverlayAssetId,
  );

  const backgroundAsset = activeTemplate.assets.find(
    (asset) => asset.id === activeTemplate.backgroundAssetId,
  );

  const handleFramePngUpload = (
    event: React.ChangeEvent<HTMLInputElement>,
  ) => {
    const file = event.target.files?.[0];

    if (!file) return;

    if (file.type !== 'image/png') {
      window.alert('Frame overlay harus PNG.');
      event.target.value = '';
      return;
    }

    const reader = new FileReader();

    reader.onload = () => {
      if (typeof reader.result !== 'string') return;

      const asset = createTemplateAsset({
        kind: 'frame-overlay',
        source: 'local',
        name: file.name,
        url: reader.result,
        mimeType: file.type,
        fileSizeBytes: file.size,
      });

      const layer = createTemplateLayer({
        name: 'Frame Overlay',
        assetId: asset.id,
        kind: 'frame-overlay',
        zIndex: 100,
        opacity: 1,
        visible: true,
      });

      addTemplateAsset(activeTemplate.id, asset);
      addTemplateLayer(activeTemplate.id, layer);
      updateTemplate(activeTemplate.id, {
        frameOverlayAssetId: asset.id,
        status: 'draft',
      });
    };

    reader.readAsDataURL(file);
    event.target.value = '';
  };

  const handleRemoveFramePng = () => {
    if (!frameOverlayAsset) return;

    if (window.confirm(`Remove frame "${frameOverlayAsset.name}"?`)) {
      removeTemplateAsset(activeTemplate.id, frameOverlayAsset.id);
    }
  };

  const handleBackgroundUpload = (
    event: React.ChangeEvent<HTMLInputElement>,
  ) => {
    const file = event.target.files?.[0];

    if (!file) return;

    if (!file.type.startsWith('image/')) {
      window.alert('Background harus file image.');
      event.target.value = '';
      return;
    }

    const reader = new FileReader();

    reader.onload = () => {
      if (typeof reader.result !== 'string') return;

      const asset = createTemplateAsset({
        kind: 'background',
        source: 'local',
        name: file.name,
        url: reader.result,
        mimeType: file.type,
        fileSizeBytes: file.size,
      });

      const layer = createTemplateLayer({
        name: 'Background',
        assetId: asset.id,
        kind: 'background',
        zIndex: 0,
        opacity: 1,
        visible: true,
      });

      addTemplateAsset(activeTemplate.id, asset);
      addTemplateLayer(activeTemplate.id, layer);
      updateTemplate(activeTemplate.id, {
        backgroundAssetId: asset.id,
        status: 'draft',
      });
    };

    reader.readAsDataURL(file);
    event.target.value = '';
  };

  const handleRemoveBackground = () => {
    if (!backgroundAsset) return;

    if (window.confirm(`Remove background "${backgroundAsset.name}"?`)) {
      removeTemplateAsset(activeTemplate.id, backgroundAsset.id);
    }
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

      <div className="mt-5">
        <TemplatePreviewCanvas template={activeTemplate} />
      </div>

      <div className="mt-5">
        <TemplateAssetSummaryPanel />
      </div>

      <div className="mt-5 rounded-3xl border border-slate-200 bg-slate-50 p-4">
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

        <div className="mt-4 grid gap-3 sm:grid-cols-8">
          <button
            type="button"
            onClick={handleCreateTemplateFromActiveLayout}
            className="rounded-2xl bg-slate-950 px-4 py-3 text-xs font-black text-white"
          >
            Create From Layout
          </button>

          <button
            type="button"
            onClick={handleSyncTemplateFromActiveLayout}
            className="rounded-2xl border border-indigo-200 bg-indigo-50 px-4 py-3 text-xs font-black text-indigo-700"
          >
            Sync Layout
          </button>

          <button
            type="button"
            onClick={handleDuplicateActiveTemplate}
            className="rounded-2xl border border-blue-200 bg-blue-50 px-4 py-3 text-xs font-black text-blue-700"
          >
            Duplicate
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
              if (window.confirm(`Delete template "${activeTemplate.name}"?`)) {
                removeTemplate(activeTemplate.id);
              }
            }}
            className="rounded-2xl border border-red-200 bg-white px-4 py-3 text-xs font-black text-red-700"
          >
            Delete
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

      <div className="mt-5 rounded-3xl border border-blue-100 bg-blue-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-blue-400">
          Frame PNG Overlay
        </p>

        <div className="mt-4 grid gap-4 lg:grid-cols-[1fr_auto] lg:items-center">
          <div>
            <p className="text-sm font-black text-blue-950">
              {frameOverlayAsset?.name || 'No frame PNG uploaded yet'}
            </p>
            <p className="mt-1 text-xs font-bold text-blue-700">
              PNG frame akan jadi layer paling atas di final output.
            </p>
          </div>

          <div className="flex flex-col gap-2 sm:flex-row">
            <label className="cursor-pointer rounded-2xl bg-blue-600 px-5 py-3 text-center text-xs font-black text-white">
              Upload PNG
              <input
                type="file"
                accept="image/png"
                onChange={handleFramePngUpload}
                className="hidden"
              />
            </label>

            {frameOverlayAsset && (
              <button
                type="button"
                onClick={handleRemoveFramePng}
                className="rounded-2xl border border-red-200 bg-white px-5 py-3 text-xs font-black text-red-700"
              >
                Remove Frame
              </button>
            )}
          </div>
        </div>

        {frameOverlayAsset?.url && (
          <div className="mt-4 rounded-2xl bg-white p-3">
            <img
              src={frameOverlayAsset.url}
              alt={frameOverlayAsset.name}
              className="mx-auto max-h-40 object-contain"
            />
          </div>
        )}
      </div>

      <div className="mt-5 rounded-3xl border border-purple-100 bg-purple-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-purple-400">
          Background Image
        </p>

        <div className="mt-4 grid gap-4 lg:grid-cols-[1fr_auto] lg:items-center">
          <div>
            <p className="text-sm font-black text-purple-950">
              {backgroundAsset?.name || 'No background uploaded yet'}
            </p>
            <p className="mt-1 text-xs font-bold text-purple-700">
              Background akan tampil di layer paling bawah.
            </p>
          </div>

          <div className="flex flex-col gap-2 sm:flex-row">
            <label className="cursor-pointer rounded-2xl bg-purple-600 px-5 py-3 text-center text-xs font-black text-white">
              Upload Background
              <input
                type="file"
                accept="image/png,image/jpeg,image/webp"
                onChange={handleBackgroundUpload}
                className="hidden"
              />
            </label>

            {backgroundAsset && (
              <button
                type="button"
                onClick={handleRemoveBackground}
                className="rounded-2xl border border-red-200 bg-white px-5 py-3 text-xs font-black text-red-700"
              >
                Remove Background
              </button>
            )}
          </div>
        </div>
      </div>

      <div className="mt-5">
        <TemplateLayerListPanel />
      </div>

      <div className="mt-5 rounded-3xl border border-dashed border-slate-300 bg-slate-50 p-5 text-center">
        <p className="text-sm font-black text-slate-700">
          Frame PNG upload sudah basic.
        </p>
        <p className="mt-1 text-xs font-semibold text-slate-500">
          Next phase kita tampilkan frame overlay di template preview.
        </p>
      </div>
    </section>
  );
}
