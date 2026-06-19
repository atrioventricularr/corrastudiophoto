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

# Add backgroundAsset const after frameOverlayAsset const.
marker = """  const frameOverlayAsset = activeTemplate.assets.find(
    (asset) => asset.id === activeTemplate.frameOverlayAssetId,
  );"""

insert = """  const frameOverlayAsset = activeTemplate.assets.find(
    (asset) => asset.id === activeTemplate.frameOverlayAssetId,
  );

  const backgroundAsset = activeTemplate.assets.find(
    (asset) => asset.id === activeTemplate.backgroundAssetId,
  );"""

if "const backgroundAsset = activeTemplate.assets.find" not in text:
    if marker not in text:
        raise SystemExit("Could not find frameOverlayAsset const.")
    text = text.replace(marker, insert, 1)

# Add background upload handler before return.
marker = """  const handleRemoveFramePng = () => {
    if (!frameOverlayAsset) return;

    if (window.confirm(`Remove frame "${frameOverlayAsset.name}"?`)) {
      removeTemplateAsset(activeTemplate.id, frameOverlayAsset.id);
    }
  };

  return ("""

insert = """  const handleRemoveFramePng = () => {
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

  return ("""

if "handleBackgroundUpload" not in text:
    if marker not in text:
        raise SystemExit("Could not find remove frame handler.")
    text = text.replace(marker, insert, 1)

# Insert UI after Frame PNG block.
marker = """      <div className="mt-5 rounded-3xl border border-blue-100 bg-blue-50 p-4">"""

# Find second major block insertion point: before Template Layer list if possible
target = """      <div className="mt-5">
        <TemplateLayerListPanel />
      </div>"""

block = """      <div className="mt-5 rounded-3xl border border-purple-100 bg-purple-50 p-4">
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

          <label className="cursor-pointer rounded-2xl bg-purple-600 px-5 py-3 text-center text-xs font-black text-white">
            Upload Background
            <input
              type="file"
              accept="image/png,image/jpeg,image/webp"
              onChange={handleBackgroundUpload}
              className="hidden"
            />
          </label>
        </div>
      </div>

"""

if "Background Image" not in text:
    if target not in text:
        raise SystemExit("Could not find TemplateLayerListPanel marker.")
    text = text.replace(target, block + target, 1)

path.write_text(text)
print("PATCH:", path)
PY

cat > apps/booth-ui/src/components/templates/TemplatePreviewCanvas.tsx <<'TSX'
import React from 'react';
import { useLayouts } from '../../layouts';
import type { PhotoTemplate } from '../../templates';

type TemplatePreviewCanvasProps = {
  template: PhotoTemplate;
};

export function TemplatePreviewCanvas({
  template,
}: TemplatePreviewCanvasProps) {
  const { layouts } = useLayouts();

  const layout = layouts.find((item) => item.id === template.layoutId);

  const backgroundLayer = template.layers.find(
    (layer) =>
      layer.assetId === template.backgroundAssetId &&
      layer.kind === 'background',
  );

  const backgroundAsset = template.assets.find(
    (asset) => asset.id === template.backgroundAssetId,
  );

  const frameLayer = template.layers.find(
    (layer) =>
      layer.assetId === template.frameOverlayAssetId &&
      layer.kind === 'frame-overlay',
  );

  const frameAsset = template.assets.find(
    (asset) => asset.id === template.frameOverlayAssetId,
  );

  const showBackground = Boolean(
    backgroundAsset?.url && (backgroundLayer?.visible ?? true),
  );

  const showFrame = Boolean(frameAsset?.url && (frameLayer?.visible ?? true));

  return (
    <div className="rounded-[2rem] border border-slate-200 bg-slate-50 p-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Template Preview
          </p>
          <h4 className="mt-1 text-xl font-black text-slate-950">
            {template.customerFacingName}
          </h4>
          <p className="mt-1 text-xs font-bold text-slate-500">
            {template.paperSnapshot.canvasWidthPx} ×{' '}
            {template.paperSnapshot.canvasHeightPx}px ·{' '}
            {template.paperSnapshot.paperName}
          </p>
        </div>

        <span className="rounded-full bg-white px-3 py-1 text-xs font-black text-slate-600">
          {showFrame ? 'Frame visible' : 'No visible frame'}
        </span>
      </div>

      <div className="mt-5 flex justify-center">
        <div className="w-full max-w-md rounded-3xl bg-slate-200 p-4">
          <div
            className="relative mx-auto w-full overflow-hidden rounded-2xl border border-slate-300 bg-white shadow-inner"
            style={{
              aspectRatio: `${template.paperSnapshot.canvasWidthPx} / ${template.paperSnapshot.canvasHeightPx}`,
            }}
          >
            {showBackground && backgroundAsset?.url && (
              <img
                src={backgroundAsset.url}
                alt={backgroundAsset.name}
                className="pointer-events-none absolute inset-0 h-full w-full object-cover"
                style={{
                  opacity: backgroundLayer?.opacity ?? 1,
                }}
              />
            )}

            <div className="absolute inset-0 bg-[linear-gradient(to_right,rgba(15,23,42,0.08)_1px,transparent_1px),linear-gradient(to_bottom,rgba(15,23,42,0.08)_1px,transparent_1px)] bg-[size:10%_10%]" />

            {layout?.slots.map((slot) => (
              <div
                key={slot.id}
                className="absolute flex items-center justify-center border-2 border-dashed border-blue-500 bg-blue-100/50 text-center"
                style={{
                  left: `${slot.xPercent}%`,
                  top: `${slot.yPercent}%`,
                  width: `${slot.widthPercent}%`,
                  height: `${slot.heightPercent}%`,
                  borderRadius:
                    slot.shape === 'circle'
                      ? '9999px'
                      : `${slot.borderRadiusPercent}%`,
                  transform: `rotate(${slot.rotationDeg}deg)`,
                }}
              >
                <p className="px-2 text-[10px] font-black uppercase text-blue-800">
                  {slot.guideLabel || slot.name}
                </p>
              </div>
            ))}

            {showFrame && frameAsset?.url && (
              <img
                src={frameAsset.url}
                alt={frameAsset.name}
                className="pointer-events-none absolute inset-0 h-full w-full object-contain"
                style={{
                  opacity: frameLayer?.opacity ?? 1,
                }}
              />
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
TSX

echo "10D1V mini done."
